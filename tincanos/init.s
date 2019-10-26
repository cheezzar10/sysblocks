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
.byte 0x8b
.short 0x0

ldt_seg:
.short 0xffff
.short 0x0
.byte 0x40
.byte 0x82
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

# nop hardware interrupt handlers for IRQ1-IRQ5
.rept 5
.short nop_hw_isr
.short code_seg_sel
.short 0x8e00
.short 0x0
.endr

.short fdc_isr
.short code_seg_sel
.short 0x8e00
.short 0x0

# nop hardware interrupt handlers for IRQ7-IRQ15
.rept 9
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

// task segment pointers referenced from system initialization code
.global sys_tss_ptr
sys_tss_ptr:
.int SYS_TSS_BASE

.global usr_tss_ptr
usr_tss_ptr:
.int USR_TSS_BASE

task_switch_addr:
.int 0x0
.short 0x0

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

# the following two macroses are not fully implemented
# they should have a parameter telling how much space
# should be reserved on stack for local variables
.macro create_stack_frame
# stack frame setup
pushl %ebp
movl %esp, %ebp

# here we should subl $?, %esp to reserve some space on the stack 

# saving registers
pushl %ebx
pushl %esi
pushl %edi
.endm

.macro destroy_stack_frame
# restoring registers
popl %edi
popl %esi
popl %ebx

# stack frame destruction
movl %ebp, %esp
popl %ebp
.endm

# here you can perform data and stack segment initialization and continue execution in pure 32 bit mode

# stack and data segment initialization
movw $0x10, %ax

movw %ax, %ds
movw %ax, %ss
movw %ax, %es
movw %ax, %gs
movw %ax, %fs

# stack top pointer init at 64k - 4 bytes
movl $STACK_TOP, %esp

movw $0x38, %ax
lldt %ax 

# enabling DMA controller (not necessary actually)
# movb $0x0, %al
# outb %al, $0x8

# system task context initialization
movw $0x28, %ax
ltr %ax

# jump to sys code entry point
# TODO rename to sys init
call sys_init

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

# TODO move to sys_init function
syscall_dispatch_loop:
jmp syscall_dispatch_loop

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
# TODO all handlers should save %eax before use
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
pushl %eax
movw $0x10, %ax
movw %ax, %ds
movw %ax, %es
movb 4(%esp), %al
addb $0x42, %al
movb $0x7, %ah
#movw $0x0725, %ax
movw %ax, 0x0b81e0
popl %eax
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

# floppy interrupt handler
fdc_isr:
pushl %eax

movw $0x10, %ax
movw %ax, %ds
movw %ax, %es
pushl $tm_msg
call print
addl $4, %esp

# FDC FIFO register number
movw $0x3f5, %dx

movb $0x7, %ah
# reading redurned status bytes one by one
inb %dx, %al
inb %dx, %al
addb $0x42, %al
movw %ax, 0x0b81e0

popl %eax

eoi
iret

# nop interrupt handler for hardware interrupt
nop_hw_isr:
eoi
iret

# programmable interrupt controller initialization
.global pic_init
pic_init:

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

ret

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

.global task_switch
task_switch:
pushfl
popl %eax
# nested task flag
orl $0x4000, %eax
pushl %eax
popfl
iret
ret

# COM port interrupt enable register offset
.equ COM_IER_OFFSET, 1
# COM port line control register offset
.equ COM_LCR_OFFSET, 3
# COM port line status register offset
.equ COM_LSR_OFFSET, 5

.global init_com_port
init_com_port:

create_stack_frame

xorl %eax, %eax
xorl %ebx, %ebx

# storing com port base register which was passed as parameter
movw 8(%ebp), %bx

# 1. configuring port baud settings
movl %ebx, %edx
addl $COM_LCR_OFFSET, %edx

# setting DLAB bit in LCR register before baud settings write
movb 0x80, %al
outb %al, %dx

# configuring max speed 115 200 bits per second
movw 0x0001, %ax

# pointing port addressing register dx to RC/TX port
movl %ebx, %edx
# writing data rate divisor LSB to port
outb %al, %dx

addl $COM_IER_OFFSET, %edx
# writing data rate divisor MSB to port
shrl $8, %eax
outb %al, %dx

# 2. configuring port mode
movl %ebx, %edx
addl $COM_LCR_OFFSET, %edx

# 8 data  bits, 1 stop bit, no parity
movb $0x3, %al
outb %al, %dx

# 3. configuring COM port to operate in non-interrupt driven mode

# zeroing out
xorl %eax, %eax
movl %ebx, %edx
addl $COM_IER_OFFSET, %edx
# writing all zeroes to IER
outb %al, %dx

destroy_stack_frame

ret

.global get_com_port_status
get_com_port_status:

create_stack_frame

xorl %eax, %eax
xorl %edx, %edx

movw 8(%ebp), %dx
addl $COM_LSR_OFFSET, %edx

inb %dx, %al

destroy_stack_frame

ret

.global putc
putc:

create_stack_frame

xorl %eax, %eax
xorl %edx, %edx

# reading COM port base parameter
movw 8(%ebp), %dx

# reading character to write
movb 12(%ebp), %al

outb %al, %dx

destroy_stack_frame

ret

# fdd status = 0x80 (ready), fdd types = 0x40
# only B drive installed, and it's of type 1.44
# when passing parameters in C style only ebp, ebx, esi, edi registers should be saved
.global fdd_init
fdd_init:
movl $0, %eax
movl $0, %ecx

# checking installed floppy drive type
movb $0x10, %al
outb %al, $0x70
inb $0x71, %al

# checking DMA controller status
inb $0x8, %al

# reading fdd main status register content
movw $0x3f4, %dx
inb %dx, %al
# drive is ready, read data command can be issued
# check for DMA status in dor register
# READ DATA command sequence 0x6, 0x1, track (0x0), 
# better use read track command, it's simpler
# this way we can transfer 9k of data in one command (and placed into 12k buffer)

# configuring DMA controller for read operation

# 1. clearing latch (next addr/count byte will be considered low) (any value written to port 0x0c)
outb %al, $0x0c
# 2. masking all channels of DMA-1 (using all mask register port 0x0f)
movb $0x0f, %al
outb %al, $0x0f
# 3. configuring buffer address (port 0x4)
movw $0x7000, %ax
outb %al, $0x04
movb %ah, %al
outb %al, $0x04
# 4. configuring bytes count (buffer length - 1) (port 0x5)
movw $0x0fff, %ax
outb %al, $0x05
movb %ah, %al
outb %al, $0x05
# 5. configuring mode (write transfer, block mode, port 0x0b)
# 6. enable block mode transfer for channel 2 (port 0x8)
movb $0x86, %al
outb %al, $0x0b
# 7. unmask channel 2 (port 0x0a)
movb $0x2, %al
outb %al, $0x0a
# 8. wait for IRQ6 when data ready

# FDC FIFO register number
movw $0x3f5, %dx

# sending READ DATA command with MFM (double density) flag set
movb $0x46, %al
outb %al, %dx

# selecting head 0, disk 0
movb $0x2, %al
outb %al, %dx

# selecting track 0
movb $0, %al
outb %al, %dx

# repeating head 0 selection
outb %al, %dx

# reading starting from sector 1
movb $1, %al
outb %al, %dx

# configuring sector size = 512 bytes
movb $0x2, %al
outb %al, %dx

# reading until sector 9
movb $0x7, %al
outb %al, %dx

# configuring GAP3 paramter to standard 3 1/2 value = 27 (intersector interval size)
movb $27, %al
outb %al, %dx

# sector size was configured to non-zero value, so sending 0xff
movb $0xff, %al
outb %al, %dx

movl $0xaa, %eax
ret
