from pathlib import Path
import re
import sys


# ============================================================
# Registros RISC-V RV32I
# ============================================================

REGS = {f"x{i}": i for i in range(32)}

REGS.update({
    "zero": 0,
    "ra":   1,
    "sp":   2,
    "gp":   3,
    "tp":   4,

    "t0":   5,
    "t1":   6,
    "t2":   7,

    "s0":   8,
    "fp":   8,
    "s1":   9,

    "a0":  10,
    "a1":  11,
    "a2":  12,
    "a3":  13,
    "a4":  14,
    "a5":  15,
    "a6":  16,
    "a7":  17,

    "s2":  18,
    "s3":  19,
    "s4":  20,
    "s5":  21,
    "s6":  22,
    "s7":  23,
    "s8":  24,
    "s9":  25,
    "s10": 26,
    "s11": 27,

    "t3":  28,
    "t4":  29,
    "t5":  30,
    "t6":  31,
})


# ============================================================
# Utilidades
# ============================================================

def get_reg(name):
    name = name.strip().lower()

    if name not in REGS:
        raise ValueError(f"Registro desconocido: {name}")

    return REGS[name]


def parse_value(text, symbols):
    """
    Convierte:
        123
        -10
        0x10040
        UART_BASE
        etiqueta
    a entero.
    """

    text = text.strip()

    if text in symbols:
        return symbols[text]

    return int(text, 0)


def signed_fits(value, bits):
    minimum = -(1 << (bits - 1))
    maximum = (1 << (bits - 1)) - 1

    return minimum <= value <= maximum


def signed32(value):
    value &= 0xFFFFFFFF

    if value & 0x80000000:
        return value - 0x100000000

    return value


# ============================================================
# Codificación de instrucciones
# ============================================================

def encode_r(opcode, rd, funct3, rs1, rs2, funct7=0):
    return (
        ((funct7 & 0x7F) << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | ((rd & 0x1F) << 7)
        | (opcode & 0x7F)
    )


def encode_i(opcode, rd, funct3, rs1, imm):
    if not signed_fits(imm, 12):
        raise ValueError(
            f"Inmediato I fuera de rango de 12 bits: {imm}"
        )

    imm &= 0xFFF

    return (
        (imm << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | ((rd & 0x1F) << 7)
        | (opcode & 0x7F)
    )


def encode_s(opcode, funct3, rs1, rs2, imm):
    if not signed_fits(imm, 12):
        raise ValueError(
            f"Inmediato S fuera de rango de 12 bits: {imm}"
        )

    imm &= 0xFFF

    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0 = imm & 0x1F

    return (
        (imm_11_5 << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | (imm_4_0 << 7)
        | (opcode & 0x7F)
    )


def encode_b(funct3, rs1, rs2, offset):
    if offset % 2 != 0:
        raise ValueError(
            f"Branch con offset no alineado: {offset}"
        )

    if not (-4096 <= offset <= 4094):
        raise ValueError(
            f"Branch fuera de rango: {offset}"
        )

    imm = offset & 0x1FFF

    imm12 = (imm >> 12) & 0x1
    imm11 = (imm >> 11) & 0x1
    imm10_5 = (imm >> 5) & 0x3F
    imm4_1 = (imm >> 1) & 0xF

    return (
        (imm12 << 31)
        | (imm10_5 << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | (imm4_1 << 8)
        | (imm11 << 7)
        | 0x63
    )


def encode_u(opcode, rd, imm20):
    return (
        ((imm20 & 0xFFFFF) << 12)
        | ((rd & 0x1F) << 7)
        | (opcode & 0x7F)
    )


def encode_j(rd, offset):
    if offset % 2 != 0:
        raise ValueError(
            f"JAL con offset no alineado: {offset}"
        )

    if not (-1048576 <= offset <= 1048574):
        raise ValueError(
            f"JAL fuera de rango: {offset}"
        )

    imm = offset & 0x1FFFFF

    imm20 = (imm >> 20) & 0x1
    imm10_1 = (imm >> 1) & 0x3FF
    imm11 = (imm >> 11) & 0x1
    imm19_12 = (imm >> 12) & 0xFF

    return (
        (imm20 << 31)
        | (imm10_1 << 21)
        | (imm11 << 20)
        | (imm19_12 << 12)
        | ((rd & 0x1F) << 7)
        | 0x6F
    )


# ============================================================
# Pseudoinstrucción LI
# ============================================================

def li_instruction_count(value):
    """
    li puede producir:

        addi rd, x0, imm

    o:

        lui  rd, upper
        addi rd, rd, lower
    """

    value = signed32(value)

    if signed_fits(value, 12):
        return 1

    return 2


def encode_li(rd, value):
    value = signed32(value)

    # Caso pequeño:
    #
    # li rd, 7
    # ->
    # addi rd, x0, 7

    if signed_fits(value, 12):
        return [
            encode_i(
                opcode=0x13,
                rd=rd,
                funct3=0b000,
                rs1=0,
                imm=value
            )
        ]

    # Caso de 32 bits:
    #
    # Se suma 0x800 antes del shift para compensar
    # la extensión de signo del ADDI inferior.

    upper = (value + 0x800) >> 12
    lower = value - (upper << 12)

    lui = encode_u(
        opcode=0x37,
        rd=rd,
        imm20=upper
    )

    addi = encode_i(
        opcode=0x13,
        rd=rd,
        funct3=0b000,
        rs1=rd,
        imm=lower
    )

    return [lui, addi]


# ============================================================
# Parseo de memoria tipo:
#
#     lw t0, 4(sp)
#     sw a0, 0(t1)
# ============================================================

def parse_memory_operand(text, symbols):
    match = re.match(
        r"^(.+?)\(([^()]+)\)$",
        text.strip()
    )

    if not match:
        raise ValueError(
            f"Operando de memoria inválido: {text}"
        )

    offset_text = match.group(1).strip()
    base_text = match.group(2).strip()

    offset = parse_value(offset_text, symbols)
    base = get_reg(base_text)

    return offset, base


# ============================================================
# Leer ASM y eliminar comentarios
# ============================================================

def read_source(path):
    result = []

    with open(path, "r", encoding="utf-8") as f:
        for line_number, raw_line in enumerate(f, start=1):

            # Quitar comentarios "# ..."
            line = raw_line.split("#", 1)[0].strip()

            if line:
                result.append(
                    (line_number, line)
                )

    return result


# ============================================================
# Primera pasada
#
# Encuentra:
#
#   .eqv
#   etiquetas
#   dirección PC de cada instrucción
# ============================================================

def first_pass(lines):
    constants = {}

    # --------------------------------------------------------
    # Primero recoger los .eqv
    # --------------------------------------------------------

    for line_number, line in lines:

        if not line.startswith(".eqv"):
            continue

        match = re.match(
            r"\.eqv\s+([A-Za-z_]\w*)\s*,\s*(.+)$",
            line
        )

        if not match:
            raise ValueError(
                f"Línea {line_number}: .eqv inválido"
            )

        name = match.group(1)
        value_text = match.group(2)

        value = parse_value(
            value_text,
            constants
        )

        constants[name] = value


    labels = {}
    instructions = []

    pc = 0

    # --------------------------------------------------------
    # Ahora calcular direcciones
    # --------------------------------------------------------

    for line_number, original_line in lines:

        line = original_line

        # Ignorar directivas
        if line.startswith("."):
            continue


        # Puede haber:
        #
        # etiqueta:
        #
        # o incluso:
        #
        # etiqueta: addi t0,t0,1

        while True:

            match = re.match(
                r"^([A-Za-z_]\w*):\s*(.*)$",
                line
            )

            if not match:
                break

            label = match.group(1)
            rest = match.group(2).strip()

            if label in labels:
                raise ValueError(
                    f"Línea {line_number}: "
                    f"etiqueta duplicada '{label}'"
                )

            labels[label] = pc

            line = rest

            if not line:
                break


        if not line:
            continue


        opcode = line.split(None, 1)[0].lower()

        # LI puede ocupar 1 o 2 instrucciones

        if opcode == "li":

            rest = line[len(opcode):].strip()

            args = [
                x.strip()
                for x in rest.split(",")
            ]

            if len(args) != 2:
                raise ValueError(
                    f"Línea {line_number}: "
                    f"li requiere 2 operandos"
                )

            value = parse_value(
                args[1],
                constants
            )

            count = li_instruction_count(value)

        else:
            count = 1


        instructions.append(
            (line_number, pc, line)
        )

        pc += 4 * count


    return constants, labels, instructions


# ============================================================
# Ensamblar una instrucción
# ============================================================

def assemble_instruction(
    line_number,
    pc,
    line,
    symbols
):

    parts = line.split(None, 1)

    opcode = parts[0].lower()

    rest = (
        parts[1].strip()
        if len(parts) > 1
        else ""
    )

    args = (
        [x.strip() for x in rest.split(",")]
        if rest
        else []
    )


    # ========================================================
    # Pseudoinstrucciones
    # ========================================================

    if opcode == "li":

        rd = get_reg(args[0])

        value = parse_value(
            args[1],
            symbols
        )

        return encode_li(
            rd,
            value
        )


    if opcode == "mv":

        rd = get_reg(args[0])
        rs = get_reg(args[1])

        # Codificación usada por el HEX original del proyecto:
        #
        # mv rd, rs
        # ->
        # add rd, x0, rs

        return [
            encode_r(
                opcode=0x33,
                rd=rd,
                funct3=0b000,
                rs1=0,
                rs2=rs,
                funct7=0
            )
        ]


    if opcode == "nop":

        return [
            encode_i(
                opcode=0x13,
                rd=0,
                funct3=0,
                rs1=0,
                imm=0
            )
        ]


    if opcode == "j":

        target = parse_value(
            args[0],
            symbols
        )

        return [
            encode_j(
                rd=0,
                offset=target - pc
            )
        ]


    # ========================================================
    # Tipo R
    # ========================================================

    if opcode in {
        "add",
        "xor",
        "or",
    }:

        rd = get_reg(args[0])
        rs1 = get_reg(args[1])
        rs2 = get_reg(args[2])

        funct3_table = {
            "add": 0b000,
            "xor": 0b100,
            "or":  0b110,
        }

        return [
            encode_r(
                opcode=0x33,
                rd=rd,
                funct3=funct3_table[opcode],
                rs1=rs1,
                rs2=rs2,
                funct7=0
            )
        ]


    # ========================================================
    # Tipo I aritmético
    # ========================================================

    if opcode in {
        "addi",
        "xori",
        "andi",
    }:

        rd = get_reg(args[0])
        rs1 = get_reg(args[1])

        imm = parse_value(
            args[2],
            symbols
        )

        funct3_table = {
            "addi": 0b000,
            "xori": 0b100,
            "andi": 0b111,
        }

        return [
            encode_i(
                opcode=0x13,
                rd=rd,
                funct3=funct3_table[opcode],
                rs1=rs1,
                imm=imm
            )
        ]


    # ========================================================
    # Shifts
    # ========================================================

    if opcode in {
        "slli",
        "srli",
    }:

        rd = get_reg(args[0])
        rs1 = get_reg(args[1])

        shamt = parse_value(
            args[2],
            symbols
        )

        if not 0 <= shamt <= 31:
            raise ValueError(
                f"shamt fuera de rango: {shamt}"
            )

        funct3 = (
            0b001
            if opcode == "slli"
            else 0b101
        )

        return [
            encode_i(
                opcode=0x13,
                rd=rd,
                funct3=funct3,
                rs1=rs1,
                imm=shamt
            )
        ]


    # ========================================================
    # Loads
    # ========================================================

    if opcode in {
        "lw",
        "lbu",
    }:

        rd = get_reg(args[0])

        offset, rs1 = parse_memory_operand(
            args[1],
            symbols
        )

        funct3_table = {
            "lw":  0b010,
            "lbu": 0b100,
        }

        return [
            encode_i(
                opcode=0x03,
                rd=rd,
                funct3=funct3_table[opcode],
                rs1=rs1,
                imm=offset
            )
        ]


    # ========================================================
    # Stores
    # ========================================================

    if opcode in {
        "sw",
        "sb",
    }:

        rs2 = get_reg(args[0])

        offset, rs1 = parse_memory_operand(
            args[1],
            symbols
        )

        funct3_table = {
            "sb": 0b000,
            "sw": 0b010,
        }

        return [
            encode_s(
                opcode=0x23,
                funct3=funct3_table[opcode],
                rs1=rs1,
                rs2=rs2,
                imm=offset
            )
        ]


    # ========================================================
    # Branches
    # ========================================================

    if opcode in {
        "beq",
        "bne",
        "blt",
        "bge",
        "bgt",
    }:

        rs1 = get_reg(args[0])
        rs2 = get_reg(args[1])

        target = parse_value(
            args[2],
            symbols
        )

        # bgt rs1, rs2, target
        #
        # equivale a:
        #
        # blt rs2, rs1, target

        actual_opcode = opcode

        if opcode == "bgt":

            actual_opcode = "blt"

            rs1, rs2 = rs2, rs1


        funct3_table = {
            "beq": 0b000,
            "bne": 0b001,
            "blt": 0b100,
            "bge": 0b101,
        }


        return [
            encode_b(
                funct3=funct3_table[actual_opcode],
                rs1=rs1,
                rs2=rs2,
                offset=target - pc
            )
        ]


    # ========================================================
    # JAL
    # ========================================================

    if opcode == "jal":

        rd = get_reg(args[0])

        target = parse_value(
            args[1],
            symbols
        )

        return [
            encode_j(
                rd=rd,
                offset=target - pc
            )
        ]


    # ========================================================
    # JALR
    #
    # jalr x0, 0(ra)
    # ========================================================

    if opcode == "jalr":

        rd = get_reg(args[0])

        offset, rs1 = parse_memory_operand(
            args[1],
            symbols
        )

        return [
            encode_i(
                opcode=0x67,
                rd=rd,
                funct3=0b000,
                rs1=rs1,
                imm=offset
            )
        ]


    raise ValueError(
        f"Instrucción no soportada: {opcode}"
    )


# ============================================================
# Ensamblador completo
# ============================================================

def assemble(source_path):

    lines = read_source(source_path)

    constants, labels, instructions = first_pass(
        lines
    )

    symbols = {}

    symbols.update(constants)
    symbols.update(labels)

    machine_code = []

    for line_number, pc, line in instructions:

        try:

            encoded = assemble_instruction(
                line_number,
                pc,
                line,
                symbols
            )

            machine_code.extend(encoded)

        except Exception as error:

            raise RuntimeError(
                f"\nError en línea {line_number}:\n"
                f"    {line}\n\n"
                f"{error}"
            ) from error


    return machine_code, labels


# ============================================================
# Guardar HEX
# ============================================================

def write_hex(path, words):

    path.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    with open(
        path,
        "w",
        encoding="ascii"
    ) as f:

        for word in words:

            f.write(
                f"{word & 0xFFFFFFFF:08x}\n"
            )


# ============================================================
# MAIN
# ============================================================

def main():

    script_dir = Path(__file__).resolve().parent

    # --------------------------------------------------------
    # Archivos
    # --------------------------------------------------------

    source = (
        script_dir
        / "batalla_naval.s"
    )

    local_hex = (
        script_dir
        / "batalla_naval.hex"
    )

    cpu_hex = (
        script_dir.parent
        / "src"
        / "cpu"
        / "program.hex"
    )

    # Existe actualmente en el repo y lo mantenemos
    # sincronizado si la carpeta sim/ está presente.

    repo_root = (
        script_dir
        .parent
        .parent
    )

    sim_dir = (
        repo_root
        / "sim"
    )

    sim_hex = (
        sim_dir
        / "program.hex"
    )


    # --------------------------------------------------------
    # Validar fuente
    # --------------------------------------------------------

    if not source.exists():

        print(
            f"ERROR: no se encontró:\n"
            f"{source}"
        )

        return 1


    # --------------------------------------------------------
    # Ensamblar
    # --------------------------------------------------------

    try:

        words, labels = assemble(
            source
        )

    except Exception as error:

        print(
            "\nASSEMBLY FAILED"
        )

        print(error)

        return 1


    # --------------------------------------------------------
    # Verificar tamaño
    #
    # ROM = 2048 palabras
    # --------------------------------------------------------

    max_words = 2048

    if len(words) > max_words:

        print(
            "\nERROR:"
        )

        print(
            f"El programa contiene "
            f"{len(words)} instrucciones."
        )

        print(
            f"La ROM solamente permite "
            f"{max_words} palabras."
        )

        return 1


    # --------------------------------------------------------
    # Escribir archivos
    # --------------------------------------------------------

    write_hex(
        local_hex,
        words
    )

    write_hex(
        cpu_hex,
        words
    )


    if sim_dir.exists():

        write_hex(
            sim_hex,
            words
        )


    # --------------------------------------------------------
    # Resultado
    # --------------------------------------------------------

    print("")
    print("========================================")
    print(" Assembly OK")
    print("========================================")

    print(
        f"Instrucciones generadas : {len(words)}"
    )

    print(
        f"Bytes utilizados        : {len(words) * 4}"
    )

    print(
        f"ROM utilizada           : "
        f"{len(words)}/{max_words} palabras"
    )

    print("")
    print("Generado:")

    print(
        f"  {local_hex}"
    )

    print(
        f"  {cpu_hex}"
    )

    if sim_dir.exists():

        print(
            f"  {sim_hex}"
        )


    print("")
    print(
        f"_start = "
        f"0x{labels.get('_start', 0):08X}"
    )

    print("")

    return 0


if __name__ == "__main__":
    sys.exit(main())