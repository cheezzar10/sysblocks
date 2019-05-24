.section .data

# GDT definition
# should be loaded on page boundary

# GDT starts with null segment descriptor
.fill 8

# code segment descriptor
code_seg:
# low 16 bits of segment limit
.short 0xffff

# low 24 bits of segment base
.short 0x0
.byte  0x0

# present bit set, privilege level 00, application segment bit is set
# code segment bit set, conforming bit is set, readable bit is clear, accessed bit is clear

# see 3.4.3.1 section of IA-32 manual for CRA fields description
# 10011010
.byte  0x9a

# granularity bit set, 32 bit is set, reserved bit is clear, available bit is clear
# limit bits all set
.byte  0xcf
.byte  0x0

# data segment descriptor (will be also used as stack segment)
data_seg:
.short 0xffff
.short 0x0
.byte  0x0

# 10010010
.byte  0x92
# 11001111
.byte  0xcf

# remaining bits of base
.byte  0x0

.align 8
# interrupt vectors definition start

# 00 priv level 0 gdt index 1 all remaining bits are zero
.equ code_seg_sel, 0x8

idt:

# !!! for the first boot interrupt processing should be disabled in loader with cli instruction
# filling the first 32 entries of IDT
.rept 32

# plain interrupt gate linked to dummy_isr
.short dummy_isr
.short code_seg_sel
.short 0x8e00
.short 0x0
.endr

.section .text

# here you can perform data and stack segment initialization and continue execution in pure 32 bit mode

init:
# stack and data segment initialization
movw $0x10, %ax

movw %ax, %ds
movw %ax, %ss
movw %ax, %es
movw %ax, %gs
movw %ax, %fs

movw $0x0723, %ax
movw %ax, 0x0b8008

lp:
jmp lp

# stack top pointer init at 128kb
movl $0x20000, %esp

# jump to sys code entry point
call start

dummy_isr:
# returning immediately
iret
