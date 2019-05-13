.section .data

# GDT definition
# should be loaded on page boundary

# GDT starts with null segment descriptor
.fill 8

# code segment descriptor

# low 16 bits of segment limit
.short 0xffff

# low 24 bits of segment base
.short 0x0000
.byte  0x00

# present bit set, privilege level 00, application segment bit is set
# code segment bit set, conforming bit is set, readable bit is clear, accessed bit is clear

# see 3.4.3.1 section of IA-32 manual for CRA fields description
# 10011100
.byte  0x9c

# granularity bit set, 32 bit is set, reserved bit is clear, available bit is clear
# limit bits all set
.byte  0xcf
.byte  0x00

# data segment descriptor (will be also used as stack segment)

.short 0xffff
.short 0x0000
.byte  0x00

# 10010010
.byte  0x92
# 11001111
.byte  0xcf

# remaining bits of base
.byte  0x00

# interrupt vectors definition start

.section .text

# here you can perform data and stack segment initialization and continue execution in pure 32 bit mode
