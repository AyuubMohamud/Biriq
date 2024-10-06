# Packed SIMD eXtensions 

## Adding PSX to binutils
Simply drag sw/binutils/riscv-opc.c to binutils/opcodes and sw/binutils/riscv-opc.h to binutils/include/opcodes

## Table of Contents

- [Addition/Subtraction](#additionsubtraction)
- [Maximum/Minimum](#maximumminimum)
- [Comparisons](#comparison)
- [Multiplications and Dot Products](#multiplications-and-dot-products)
- [Shifts and Rotates](#shifts-and-rotates)
- [Permuations](#permutations)
- [Unsigned Sum of Absolute Differences](#unsigned-sum-of-absolute-differences)
## Instructions
### Addition/Subtraction 
#### psx.add16 rd, rs1, rs2
Add two packed 16-bit values in rs1 to two packed 16-bit values in rs2.
```C++
void psx_add16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = rs1[0] + rs2[0];
    rd[1] = rs1[1] + rs2[1];
    return;
}
```
#### psx.add8 rd, rs1, rs2
Add four packed 8-bit values in rs1 to four packed 8-bit values in rs2.
```C++
void psx_add8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = rs1[0] + rs2[0];
    rd[1] = rs1[1] + rs2[1];
    rd[2] = rs1[2] + rs2[2];
    rd[3] = rs1[3] + rs2[3];
    return;
}
```
#### psx.sub16 rd, rs1, rs2
Subtract two packed 16-bit values in rs1 from two packed 16-bit values in rs2.
```C++
void psx_add16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = rs1[0] - rs2[0];
    rd[1] = rs1[1] - rs2[1];
    return;
}
```
#### psx.sub8 rd, rs1, rs2
Subtract four packed 8-bit values in rs1 from four packed 8-bit values in rs2.
```C++
void psx_add8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = rs1[0] - rs2[0];
    rd[1] = rs1[1] - rs2[1];
    rd[2] = rs1[2] - rs2[2];
    rd[3] = rs1[3] - rs2[3];
    return;
}
```
#### psx.kadd16 rd, rs1, rs2
Add two packed 16-bit values in rs1 to two packed 16-bit values in rs2 and perform signed saturation.
```C++
void psx_kadd16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = saturate_signed(rs1[0] + rs2[0]);
    rd[1] = saturate_signed(rs1[1] + rs2[1]);
    return;
}
```
#### psx.kadd8 rd, rs1, rs2
Add four packed 8-bit values in rs1 to four packed 8-bit values in rs2 and perform signed saturation.
```C++
void psx_kadd8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] =  saturate_signed(rs1[0] + rs2[0]);
    rd[1] =  saturate_signed(rs1[1] + rs2[1]);
    rd[2] =  saturate_signed(rs1[2] + rs2[2]);
    rd[3] =  saturate_signed(rs1[3] + rs2[3]);
    return;
}
```
#### psx.kuadd16 rd, rs1, rs2
Add two packed 16-bit values in rs1 to two packed 16-bit values in rs2 and perform unsigned saturation.
```C++
void psx_kuadd16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = saturate_unsigned(rs1[0] + rs2[0]);
    rd[1] = saturate_unsigned(rs1[1] + rs2[1]);
    return;
}
```
#### psx.kuadd8 rd, rs1, rs2
Add four packed 8-bit values in rs1 to four packed 8-bit values in rs2 and perform unsigned saturation.
```C++
void psx_kuadd8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] =  saturate_unsigned(rs1[0] + rs2[0]);
    rd[1] =  saturate_unsigned(rs1[1] + rs2[1]);
    rd[2] =  saturate_unsigned(rs1[2] + rs2[2]);
    rd[3] =  saturate_unsigned(rs1[3] + rs2[3]);
    return;
}
```
#### psx.ksub16 rd, rs1, rs2
Subtract two packed 16-bit values in rs1 from two packed 16-bit values in rs2 and perform signed saturation.
```C++
void psx_ksub16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = saturate_signed(rs1[0] - rs2[0]);
    rd[1] = saturate_signed(rs1[1] - rs2[1]);
    return;
}
```
#### psx.ksub8 rd, rs1, rs2
Subtract four packed 8-bit values in rs1 from four packed 8-bit values in rs2 and perform signed saturation.
```C++
void psx_ksub8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] =  saturate_signed(rs1[0] - rs2[0]);
    rd[1] =  saturate_signed(rs1[1] - rs2[1]);
    rd[2] =  saturate_signed(rs1[2] - rs2[2]);
    rd[3] =  saturate_signed(rs1[3] - rs2[3]);
    return;
}
```
#### psx.kusub16 rd, rs1, rs2
Subtract two packed 16-bit values in rs1 from two packed 16-bit values in rs2 and perform unsigned saturation.
```C++
void psx_kusub16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = saturate_unsigned(rs1[0] - rs2[0]);
    rd[1] = saturate_unsigned(rs1[1] - rs2[1]);
    return;
}
```
#### psx.kusub8 rd, rs1, rs2
Subtract four packed 8-bit values in rs1 from four packed 8-bit values in rs2 and perform unsigned saturation.
```C++
void psx_kusub8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] =  saturate_unsigned(rs1[0] - rs2[0]);
    rd[1] =  saturate_unsigned(rs1[1] - rs2[1]);
    rd[2] =  saturate_unsigned(rs1[2] - rs2[2]);
    rd[3] =  saturate_unsigned(rs1[3] - rs2[3]);
    return;
}
```
### Maximum/Minimum
#### psx.max16 rd, rs1, rs2
Return the signed maximum between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_max16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    for (uint32_t count = 0; count < 2; count++) {
        if ((int16_t)(rs1[count]) > (int16_t)(rs2[count])) {
            rd[count] = rs1[count];
        } else {
            rd[count] = rs2[count];
        }
    }
    return;
}
```
#### psx.max8 rd, rs1, rs2
Return the signed maximum between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_max8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    for (uint32_t count = 0; count < 4; count++) {
        if ((int8_t)(rs1[count]) > (int8_t)(rs2[count])) {
            rd[count] = rs1[count];
        } else {
            rd[count] = rs2[count];
        }
    }
    return;
}
```
#### psx.umax16 rd, rs1, rs2
Return the unsigned maximum between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_umax16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    for (uint32_t count = 0; count < 2; count++) {
        if (rs1[count] > rs2[count]) {
            rd[count] = rs1[count];
        } else {
            rd[count] = rs2[count];
        }
    }
    return;
}
```
#### psx.umax8 rd, rs1, rs2
Return the unsigned maximum between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_umax8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    for (uint32_t count = 0; count < 4; count++) {
        if (rs1[count] > rs2[count]) {
            rd[count] = rs1[count];
        } else {
            rd[count] = rs2[count];
        }
    }
    return;
}
```
#### psx.min16 rd, rs1, rs2
Return the signed minimum between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_min16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    for (uint32_t count = 0; count < 2; count++) {
        if ((int16_t)(rs1[count]) < (int16_t)(rs2[count])) {
            rd[count] = rs1[count];
        } else {
            rd[count] = rs2[count];
        }
    }
    return;
}
```
#### psx.min8 rd, rs1, rs2
Return the signed minimum between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_min8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    for (uint32_t count = 0; count < 4; count++) {
        if ((int8_t)(rs1[count]) < (int8_t)(rs2[count])) {
            rd[count] = rs1[count];
        } else {
            rd[count] = rs2[count];
        }
    }
    return;
}
```
#### psx.umin16 rd, rs1, rs2
Return the unsigned minimum between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_umin16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    for (uint32_t count = 0; count < 2; count++) {
        if (rs1[count] < rs2[count]) {
            rd[count] = rs1[count];
        } else {
            rd[count] = rs2[count];
        }
    }
    return;
}
```
#### psx.umax8 rd, rs1, rs2
Return the unsigned minimum between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_umin8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    for (uint32_t count = 0; count < 4; count++) {
        if (rs1[count] < rs2[count]) {
            rd[count] = rs1[count];
        } else {
            rd[count] = rs2[count];
        }
    }
    return;
}
```
### Comparison
#### psx.ceq16 rd, rs1, rs2
Compare for equlity between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_ceq16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = (rs1[0]==rs2[0]) ? 0xFF : 0x00;
    rd[1] = (rs1[1]==rs2[1]) ? 0xFF : 0x00;
    return;
}
```
#### psx.ceq8 rd, rs1, rs2
Compare for equlity between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_ceq8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = (rs1[0]==rs2[0]) ? 0xFF : 0x00;
    rd[1] = (rs1[1]==rs2[1]) ? 0xFF : 0x00;
    rd[2] = (rs1[2]==rs2[2]) ? 0xFF : 0x00;
    rd[3] = (rs1[3]==rs2[3]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cne16 rd, rs1, rs2
Compare for inequlity between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_cne16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = (rs1[0]!=rs2[0]) ? 0xFF : 0x00;
    rd[1] = (rs1[1]!=rs2[1]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cne8 rd, rs1, rs2
Compare for inequlity between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_cne8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = (rs1[0]!=rs2[0]) ? 0xFF : 0x00;
    rd[1] = (rs1[1]!=rs2[1]) ? 0xFF : 0x00;
    rd[2] = (rs1[2]!=rs2[2]) ? 0xFF : 0x00;
    rd[3] = (rs1[3]!=rs2[3]) ? 0xFF : 0x00;
    return;
}
```
#### psx.clt16 rd, rs1, rs2
Compare for signed less than between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_clt16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = ((int16_t)rs1[0]<(int16_t)rs2[0]) ? 0xFF : 0x00;
    rd[1] = ((int16_t)rs1[1]<(int16_t)rs2[1]) ? 0xFF : 0x00;
    return;
}
```
#### psx.clt8 rd, rs1, rs2
Compare for signed less than between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_clt8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = ((int16_t)rs1[0]<(int16_t)rs2[0]) ? 0xFF : 0x00;
    rd[1] = ((int16_t)rs1[1]<(int16_t)rs2[1]) ? 0xFF : 0x00;
    rd[2] = ((int16_t)rs1[2]<(int16_t)rs2[2]) ? 0xFF : 0x00;
    rd[3] = ((int16_t)rs1[3]<(int16_t)rs2[3]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cle16 rd, rs1, rs2
Compare for signed less than or equals between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_cle16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = ((int16_t)rs1[0]<(int16_t)rs2[0]) ? 0xFF : 0x00;
    rd[1] = ((int16_t)rs1[1]<(int16_t)rs2[1]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cle8 rd, rs1, rs2
Compare for signed less than or equals between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_cle8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = ((int16_t)rs1[0]<=(int16_t)rs2[0]) ? 0xFF : 0x00;
    rd[1] = ((int16_t)rs1[1]<=(int16_t)rs2[1]) ? 0xFF : 0x00;
    rd[2] = ((int16_t)rs1[2]<=(int16_t)rs2[2]) ? 0xFF : 0x00;
    rd[3] = ((int16_t)rs1[3]<=(int16_t)rs2[3]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cgt16 rd, rs1, rs2
Compare for signed greater than between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_cgt16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = ((int16_t)rs1[0]>(int16_t)rs2[0]) ? 0xFF : 0x00;
    rd[1] = ((int16_t)rs1[1]>(int16_t)rs2[1]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cgt8 rd, rs1, rs2
Compare for signed greater than between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_cgt8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = ((int16_t)rs1[0]>(int16_t)rs2[0]) ? 0xFF : 0x00;
    rd[1] = ((int16_t)rs1[1]>(int16_t)rs2[1]) ? 0xFF : 0x00;
    rd[2] = ((int16_t)rs1[2]>(int16_t)rs2[2]) ? 0xFF : 0x00;
    rd[3] = ((int16_t)rs1[3]>(int16_t)rs2[3]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cltu16 rd, rs1, rs2
Compare for unsigned less than between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_cltu16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = (rs1[0]<rs2[0]) ? 0xFF : 0x00;
    rd[1] = (rs1[1]<rs2[1]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cltu8 rd, rs1, rs2
Compare for unsigned less than between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_cltu8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = (rs1[0]<rs2[0]) ? 0xFF : 0x00;
    rd[1] = (rs1[1]<rs2[1]) ? 0xFF : 0x00;
    rd[2] = (rs1[2]<rs2[2]) ? 0xFF : 0x00;
    rd[3] = (rs1[3]<rs2[3]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cleu16 rd, rs1, rs2
Compare for unsigned less than or equals between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_cleu16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = (rs1[0]<rs2[0]) ? 0xFF : 0x00;
    rd[1] = (rs1[1]<rs2[1]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cleu8 rd, rs1, rs2
Compare for unsigned less than or equals between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_cleu8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = (rs1[0]<=rs2[0]) ? 0xFF : 0x00;
    rd[1] = (rs1[1]<=rs2[1]) ? 0xFF : 0x00;
    rd[2] = (rs1[2]<=rs2[2]) ? 0xFF : 0x00;
    rd[3] = (rs1[3]<=rs2[3]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cgtu16 rd, rs1, rs2
Compare for unsigned greater than between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_cgtu16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = (rs1[0]>rs2[0]) ? 0xFF : 0x00;
    rd[1] = (rs1[1]>rs2[1]) ? 0xFF : 0x00;
    return;
}
```
#### psx.cgtu8 rd, rs1, rs2
Compare for unsigned greater than between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_cgt8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = (rs1[0]>rs2[0]) ? 0xFF : 0x00;
    rd[1] = (rs1[1]>rs2[1]) ? 0xFF : 0x00;
    rd[2] = (rs1[2]>rs2[2]) ? 0xFF : 0x00;
    rd[3] = (rs1[3]>rs2[3]) ? 0xFF : 0x00;
    return;
}
```
### Multiplications and Dot Products
#### psx.mll16 rd, rs1, rs2
Signed multiplication of two packed 16-bit values in rs1 and two packed 16-bit values in rs2 returning lower 16-bits.
```C++
void psx_mll16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = ((uint32_t)rs1[0]*(uint32_t)rs2[0])&0x0000FFFF;
    rd[1] = ((uint32_t)rs1[1]*(uint32_t)rs2[1])&0x0000FFFF;
    return;
}
```
#### psx.mlh16 rd, rs1, rs2
Signed multiplication of two packed 16-bit values in rs1 and two packed 16-bit values in rs2 returning higher 16-bits.
```C++
void psx_mlh16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = ((uint32_t)rs1[0]*(uint32_t)rs2[0])>>16;
    rd[1] = ((uint32_t)rs1[1]*(uint32_t)rs2[1])>>16;
    return;
}
```
#### psx.dot2d rd, rs1, rs2
Signed multiplication of two packed 16-bit values in rs1 and two packed 16-bit values in rs2 and addition of both results together into a 32-bit accumulator.
```C++
void psx_dot2d(uint16_t[2] rs1, uint16_t[2] rs2, uint32_t rd) {
    rd = ((uint32_t)rs1[0]*(uint32_t)rs2[0])+((uint32_t)rs1[1]*(uint32_t)rs2[1]);
    return;
}
```
### Shifts and Rotates
#### psx.sll16 rd, rs1, rs2
Shift left two packed 16-bit values in rs1 by a shift amount inside two packed 16-bit values in rs2.
```C++
void psx_sll16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = rs1[0] << rs2[0];
    rd[1] = rs1[1] << rs2[1];
    return;
}
```
#### psx.sll8 rd, rs1, rs2
Shift left four packed 8-bit values in rs1 by a shift amount inside four packed 8-bit values in rs2.
```C++
void psx_sll8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = rs1[0] << rs2[0];
    rd[1] = rs1[1] << rs2[1];
    rd[2] = rs1[2] << rs2[2];
    rd[3] = rs1[3] << rs2[3];
    return;
}
```
#### psx.srl16 rd, rs1, rs2
Shift right two packed 16-bit values in rs1 by a shift amount inside two packed 16-bit values in rs2.
```C++
void psx_srl16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = rs1[0] >> rs2[0];
    rd[1] = rs1[1] >> rs2[1];
    return;
}
```
#### psx.srl8 rd, rs1, rs2
Shift right four packed 8-bit values in rs1 by a shift amount inside four packed 8-bit values in rs2.
```C++
void psx_srl8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = rs1[0] >> rs2[0];
    rd[1] = rs1[1] >> rs2[1];
    rd[2] = rs1[2] >> rs2[2];
    rd[3] = rs1[3] >> rs2[3];
    return;
}
```
#### psx.sra16 rd, rs1, rs2
Signed shift right two packed 16-bit values in rs1 by a shift amount inside two packed 16-bit values in rs2.
```C++
void psx_sra16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = rs1[0] >>> rs2[0];
    rd[1] = rs1[1] >>> rs2[1];
    return;
}
```
#### psx.sra8 rd, rs1, rs2
Signed shift right four packed 8-bit values in rs1 by a shift amount inside four packed 8-bit values in rs2.
```C++
void psx_sra8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = rs1[0] >>> rs2[0];
    rd[1] = rs1[1] >>> rs2[1];
    rd[2] = rs1[2] >>> rs2[2];
    rd[3] = rs1[3] >>> rs2[3];
    return;
}
```
#### psx.rol16 rd, rs1, rs2
Rotate left two packed 16-bit values in rs1 by a shift amount inside two packed 16-bit values in rs2.
```C++
void psx_rol16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] =  rotate_left(rs1[0],rs2[0]);
    rd[1] =  rotate_left(rs1[1],rs2[1]);
    return;
}
```
#### psx.rol8 rd, rs1, rs2
Rotate left four packed 8-bit values in rs1 by a shift amount inside four packed 8-bit values in rs2.
```C++
void psx_rol8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = rotate_left(rs1[0],rs2[0]);
    rd[1] = rotate_left(rs1[1],rs2[1]);
    rd[2] = rotate_left(rs1[2],rs2[2]);
    rd[3] = rotate_left(rs1[3],rs2[3]);
    return;
}
```
#### psx.ror16 rd, rs1, rs2
Rotate right two packed 16-bit values in rs1 by a shift amount inside two packed 16-bit values in rs2.
```C++
void psx_ror16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] =  rotate_right(rs1[0],rs2[0]);
    rd[1] =  rotate_right(rs1[1],rs2[1]);
    return;
}
```
#### psx.ror8 rd, rs1, rs2
Rotate right four packed 8-bit values in rs1 by a shift amount inside four packed 8-bit values in rs2.
```C++
void psx_ror8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = rotate_right(rs1[0],rs2[0]);
    rd[1] = rotate_right(rs1[1],rs2[1]);
    rd[2] = rotate_right(rs1[2],rs2[2]);
    rd[3] = rotate_right(rs1[3],rs2[3]);
    return;
}
```
### Permutations
#### psx.perm8 rd, rs1, rs2
Select bytes from rs1 using byte indexes from rs2.
```C++
void psx_add8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = rs2[0]&0x80000000 ? 0x00 : rs1[rs2[0]];
    rd[1] = rs2[1]&0x80000000 ? 0x00 : rs1[rs2[1]];
    rd[2] = rs2[2]&0x80000000 ? 0x00 : rs1[rs2[2]];
    rd[3] = rs2[3]&0x80000000 ? 0x00 : rs1[rs2[3]];
    return;
}
```
#### psx.pack8 rd, rs1, rs2
Pack together a 16 bit value from the low 8-bits of rs1 and rs2.
```C++
void psx_add8(uint8_t[4] rs1, uint8_t[4] rs2, uint8_t[4] rd) {
    rd[0] = rs2[0];
    rd[1] = rs1[0];
    rd[2] = 0x00;
    rd[3] = 0x00;
    return;
}
```
#### psx.pack16 rd, rs1, rs2
Pack together a 32 bit value from the low 16-bits of rs1 and rs2.
```C++
void psx_add16(uint16_t[2] rs1, uint16_t[2] rs2, uint16_t[2] rd) {
    rd[0] = rs2[0];
    rd[1] = rs1[0];
    return;
}
```
### Unsigned sum of absolute differences
#### psx.usad8 rd, rs1, rs2
Unsigned sum of absolute differences between four packed 8-bit values in rs1 and four packed 8-bit values in rs2.
```C++
void psx_add8(uint8_t[4] rs1, uint8_t[4] rs2, uint32_t rd) {
    uint8_t temp[4];
    temp[0] = abs(rs1[0] - rs2[0]);
    temp[1] = abs(rs1[1] - rs2[1]);
    temp[2] = abs(rs1[2] - rs2[2]);
    temp[3] = abs(rs1[3] - rs2[3]);
    
    rd = temp[0]+temp[1]+temp[2]+temp[3];
    return;
}
```
#### psx.usad16 rd, rs1, rs2
Unsigned sum of absolute differences between two packed 16-bit values in rs1 and two packed 16-bit values in rs2.
```C++
void psx_add8(uint16_t[2] rs1, uint16_t[2] rs2, uint32_t rd) {
    uint16_t temp[2];
    temp[0] = abs(rs1[0] - rs2[0]);
    temp[1] = abs(rs1[1] - rs2[1]);
    
    rd = temp[0]+temp[1];
    return;
}
```