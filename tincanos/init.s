.section .data

# GDT definition

# GDT starts with null segment descriptor
.fill 8

# code segment descriptor
.short 0xffff
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


.section .text

# protected mode switching code will go here
