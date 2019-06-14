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

# 0. divide error fault handler descriptor
.short de_isr
.short code_seg_sel
# fault
.short 0x8e00
.short 0x0

# 1. Intel reserved handler descriptor
.short nop_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 2. non-maskable external interrupt handler
.short nop_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 3. breakpoint trap handler
.short nop_isr
.short code_seg_sel
.short 0x8f00
.short 0x0

# 4. overflow trap handler
.short nop_isr
.short code_seg_sel
.short 0x8f00
.short 0x0

# 5. bound range exceeded fault handler
.short nop_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 6. invalid opcode fault handler
.short ud_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 7. device not available fault handler
.short nop_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 8. double fault handler
.short df_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 9. co-processor segment overrun fault handler
.short nop_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 10. invalid TSS fault handler
.short nop_err_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 11. segment not present fault handler
.short np_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 12. stack segment fault handler
.short nop_err_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 13. general protection fault handler
.short gp_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 14. page fault handler
.short nop_err_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 15. Intel reserved fault handler
.short nop_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 16. floating point error fault handler
.short nop_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 17. alignment check fault handler
.short nop_err_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 18. machine check fault handler
.short nop_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 19. SIMD floating point fault handler
.short nop_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 20-31 Intel reserved fault handlers
.rept 12
.short nop_isr
.short code_seg_sel
.short 0x8e00
.short 0x0
.endr

# IRQ specific interrupt handlers will go here


idt_data:
# idt limit 32 * 8 - 1 (2 bytes)
.short 0xff
.int idt

de_msg:
.asciz "divide error\n"

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

lidt idt_data
sti

# print '#' symbol on screen
movw $0x0723, %ax
movw %ax, 0x0b8002

# stack top pointer init at 64k - 4 bytes
movl $0xfffc, %esp

# jump to sys code entry point
call start

# divide error handler (fault 0)
de_isr:
pushl $de_msg
call print
addl $4, %esp

# fixing divide error - jumping 3 bytes (length of idiv)
movl (%esp), %eax
addl $3, %eax
movl %eax, (%esp)

iret

# undefined opcode handler (fault 6)
ud_isr:
iret

# double fault (abort 8)
df_isr:
iret

# segment not present (fault 11)
np_isr:
iret

# general protection (fault 13)
gp_isr:
iret

# empty interrupt handler
nop_isr:
iret

# empty fault handler for case when error code is present
nop_err_isr:
# removing error code from stack
addl $4, %esp
iret

.global get_eflags
get_eflags:
pushfl
popl %eax
ret
