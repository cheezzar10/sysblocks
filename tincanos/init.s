.section .data

# GDT definition
# should be loaded on page boundary

# GDT starts with null segment descriptor
.fill 8

# system code segment descriptor
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

# system data segment descriptor (will be also used as stack segment)
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

# user code/data segment descriptors of the same location and size as the system ones (@0 4G size)
# user code segment descriptor
usr_code_seg:
.short 0xffff
.short 0x0
.byte 0x0
# 11111000 - present, privilege level 3, execute only segment
.byte 0xf8
# 11001111
.byte 0xcf
.byte 0x0

# user data segment descriptor
usr_data_seg:
.short 0xffff
.short 0x0
.byte 0x0
# 11110010 - present, priv level 3, read/write data segment
.byte 0xf2
.byte 0xcf
.byte 0x0

sys_task_seg:
# I/O map base address is relative to task segment base
# so we'll use I/O map base address which is greater or equal to task segment limit
# task segment limit
.short 0x67
.short SYS_TSS_BASE
.byte 0x0
# 10001001 - present, system (privilege level 0), non-busy
.byte 0x89
.short 0x0

usr_task_seg:
.short 0x67
.short USR_TSS_BASE
.byte 0x0
# 10001001 - present, system (priv level 0 - only system code can perform task switch), busy bit clear
.byte 0x89
.short 0x0

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
.short ts_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 11. segment not present fault handler
.short np_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# 12. stack segment fault handler
.short ss_isr
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

# 32. IRQ0 (timer) interrupt handler
.short timer_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# nop hardware interrupt handlers for IRQ1-IRQ15
.rept 15
.short nop_hw_isr
.short code_seg_sel
.short 0x8e00
.short 0x0
.endr

idt_data:
# idt limit 48 * 8 - 1 (383 bytes)
.short 0x17f
.int idt

de_msg:
.asciz "divide error\n"
tm_msg:
.asciz "@"

.global sys_tss_base
sys_tss_base:
.int SYS_TSS_BASE

.global usr_tss_base
usr_tss_base:
.int USR_TSS_BASE

.section .text

.macro eoi
# saving
pushl %eax
# sending notification to master/slave interrupt controllers about processed interrupt
movb $0x20, %al
outb %al, $0x20
outb %al, $0xa0
# restoring
popl %eax
.endm

# here you can perform data and stack segment initialization and continue execution in pure 32 bit mode

init:
# stack and data segment initialization
movw $0x10, %ax

movw %ax, %ds
movw %ax, %ss
movw %ax, %es
movw %ax, %gs
movw %ax, %fs

# performing interrupt controller initialization

# ICW1 edge triggered mode, cascade mode & ICW4 will be provided
movb $0x11, %al
outb %al, $0x20
outb %al, $0xa0
# ICW2 master controller will use vectors starting from 32-39 (0x20)
movb $0x20, %al
outb %al, $0x21
movb $0x28, %al
outb %al, $0xa1
# ICW3 slave controller connected to IRQ2 of master
movb $0x4, %al
outb %al, $0x21
movb $0x2, %al
outb %al, $0xa1
# ICW4 x86 bit set, other bits clear which means normal EOI, nonbuffered
movb $0x1, %al
outb %al, $0x21
outb %al, $0xa1

# unmasking all interrupts for master and slave
movb $0, %al
outb %al, $0x21
outb %al, $0xa1

# loading intr descriptors table
lidt idt_data

# enabling interrupts
sti

# stack top pointer init at 64k - 4 bytes
movl $STACK_TOP, %esp

# checking timer interrupt manually
# int $0x20

# sample timer configuration (counter 0, rate LSB/MSB, square wave mode 3, binary counter)
# 00110110 - 0x36
# movb $0x36, %al
# sending control word to timer control registerl
# outb %al, $0x43
# movb 0,  %al
# sending divisor LSB
# outb %al, $0x40
# sending divisor MSB
# outb %al, $0x40

# jump to sys code entry point
call start

# setting system task context
movw $0x28, %ax
ltr %ax

movw $0x077e, %ax
movw %ax, 0x0b8140

# switching to user task
ljmp $0x30, $0

lllll:
jmp lllll

# divide error handler (fault 0)
de_isr:
pushl $de_msg
call print
addl $4, %esp

# saving
pushl %eax
# TODO cleaner way to skip failed instruction retry is to clear RF flag
# fixing divide error - jumping 3 bytes (length of idiv)
movl (%esp), %eax
addl $3, %eax
# restoring
movl %eax, (%esp)

popl %eax

iret

# undefined opcode handler (fault 6)
ud_isr:
movw $0x10, %ax
movw %ax, %ds
movw %ax, %es
movw $0x077c, %ax
movw %ax, 0x0b81e0
iret

# double fault (abort 8)
df_isr:
movw $0x10, %ax
movw %ax, %ds
movw %ax, %es
movw $0x0721, %ax
movw %ax, 0x0b81e0
addl $4, %esp
iret

# invalid TSS fault handler
ts_isr:
movw $0x10, %ax
movw %ax, %ds
movw %ax, %es
movw $0x0724, %ax
movw %ax, 0x0b81e0
addl $4, %esp
iret

# segment not present (fault 11)
np_isr:
movw $0x10, %ax
movw %ax, %ds
movw %ax, %es
movw $0x072a, %ax
movw %ax, 0x0b81e0
addl $4, %esp
iret

# stack segment fault (fault 12)
ss_isr:
movw $0x10, %ax
movw %ax, %ds
movw %ax, %es
movw $0x072b, %ax
movw %ax, 0x0b81e0
addl $4, %esp
iret

# general protection (fault 13)
gp_isr:
movw $0x10, %ax
movw %ax, %ds
movw $0x0725, %ax
movw %ax, 0x0b81e0
addl $4, %esp
iret

# empty interrupt handler
nop_isr:
iret

# empty fault handler for case when error code is present
nop_err_isr:
# removing error code from stack
addl $4, %esp
iret

# timer interrupt handler
timer_isr:
movw $0x10, %ax
movw %ax, %ds
movw %ax, %es
#pushl $tm_msg
#call print
#addl $4, %esp
eoi
iret

# nop interrupt handler for hardware interrupt
nop_hw_isr:
eoi
iret

.global get_eflags
get_eflags:
pushfl
popl %eax
ret

.global get_ldtr
get_ldtr:
movl %cs, %eax
# mov $0, %eax
# sldt %ax
ret

.global task
task:
movw $0x0724, %ax
movw %ax, 0x0b8140
call user_task
