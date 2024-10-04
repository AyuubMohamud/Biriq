# Packed SIMD eXtensions 

ADD8, ADD16 func7 = 0x00 : Normal addition of packed 8-bit/16-bit values

SUB8, SUB16 func7 = 0x01 : Normal subtraction of packed 8-bit/16-bit values 

KADD8, KADD16 func7 = 0x06  : Saturated signed addition of packed 8-bit/16-bit values

KUADD8, KUADD16 func7 = 0x04 : Saturated unsigned addition of packed 8-bit/16-bit values

KSUB8, KSUB16 func7 = 0x07 : Saturated signed subtraction of packed 8-bit/16-bit values

KUSUB8, KUSUB16 func7 = 0x05 : Saturated unsigned subtraction of packed 8-bit/16-bit values

MAX8, MAX16 func7 = 0x18 : Signed maximum

UMAX8, UMAX16 func7 = 0x10 : Unsigned maximum

MIN8, MIN16 func7 = 0x19 : Signed minimum

UMIN8, UMIN16 func7 = 0x11 : Unsigned minimum

CEQ8, CEQ16 func7 = 0x14 : Bitfield becomes 1 on condition EQUAL

CNE8, CNE16 func7 = 0x1C : Bitfield becomes 1 on condition NOT EQUAL

CLT8, CLT16 func7 = 0x1D : Bitfield becomes 1 on condition LESS THAN

CLE8, CLE16 func7 = 0x1E : Bitfield becomes 1 on condition LESS THAN OR EQUAL

CGT8, CGT16 func7 = 0x1F : Bitfield becomes 1 on condition GREATER THAN

CLTU8, CLTU16 func7 = 0x15 : Bitfield becomes 1 on condition LESS THAN UNSIGNED

CLEU8, CLEU16 func7 = 0x16 : Bitfield becomes 1 on condition LESS THAN UNSIGNED OR EQUAL

CGTU8, CGTU16 func7 = 0x17 : Bitfield becomes 1 on condition GREATER THAN UNSIGNED OR EQUAL

MLL16 func7: 0x20: Signed Multiply two 16-bit values store lower 16 bits of both products

MLH16 func7: 0x21: Signed Multiply two 16-bit values store higher 16 bits of both products

DOT2D func7: 0x22: Signed dot product of two 16-bit vectors -> rd = rs1[31:16] x rs2[31:16] + rs1[15:0] x rs2[15:0]

SLL8, SLL16 func7 = 0x30 : Shift left

SRL8, SRL16 func7 = 0x31 : Shift right

ROL8, ROL16 func7 = 0x32 : Rotate left

ROR8, ROR16 func7 = 0x33 : Rotate right

SRA8, SRA16 func7 = 0x35 : Signed shift right

size determined by 6th bit of func7 (op[6] ? 16-bit ops : 8-bit ops)

OP-PSX resides in CUSTOM-1