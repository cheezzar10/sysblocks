[bits 16]
; actual memory offset should be 7c00 + mbr header length
; right now i think that lgdt should use 16 bit displacement cause
; we are not using memory operand instruction mode override prefix
; but in case of any problems we can try to use 32 bit address
[org 7c3eh]

; dos sample command
; nasm loader.asm -f bin -o loader.com
; after that you can 'dd' it to MBR with offset relative to the start of cluster

[section .text]

; clearing screen

; ah - scroll up, al - entire screen
mov ax, 0600h
; normal 07 attribute for all symbols on the screen
mov bh, 7
; cl - top left col, ch - top left row
mov cx, 0
; dh - bottom right col 24, dl bottom right row 79
mov dx, 184fh
int 10h

; es register init required for image read buf
mov ax, 0
mov es, ax

; loading image right at the 32kb origin

; requesting read service 02h
mov ah, 02h
; trying to read 16 sectors at once
mov al, 16
; loading at 32kb 
mov bx, 8000h
; selecting track 0
mov ch, 0
; selecting start sector 2
mov cl, 2
; selecting head 0
mov dh, 0
; selecting drive 0
mov dl, 0

; reading binary image
int 13h

; skipping read sectors count display in case of error
jc read_err

read_err:
clc
; displaying @ before interrupt flag clear
mov di, 0

mov ax, 0740h
mov [es:di], ax

; disabling iterrupts
cli

; may be NMI interrupts should be masked too
in al, 70h
or al, 80h
out 70h, al

; loading global descriptor table
lgdt [lgdt_data]

sgdt [gdt_test]

; 0x03, 0x00, 0x00, 0x80, 0x00, 0x00
mov al, byte [800eh]
; saving read sectors count
mov dx, 0
mov dl, al

; displaying read sectors count contained in al
mov ax, 0b800h
mov es, ax

; screen buf offset
mov di, 4
; 1 byte - 2 chars
mov cx, 2

hex_byte_print:
mov bl, dl
and bx, 0fh

; getting character from table and using normal 07 attr
mov al, byte [hex_chr_buf+bx]
mov ah, 07h

mov [es:di], ax
sub di, 2

shr dl, 4

dec cx
cmp cx, 0

jnz hex_byte_print

; set protection flag
mov eax, cr0
or eax, 1
mov cr0, eax

; interrupt vectors can be loaded after switch to protected mode

[section .data]

init_far_jmp:
; encoding far jmp directly
db 0eah
; tables are on 32kb + 4kb image code section alignment
dw 9000h
; code segment selector
dw 08h

; after previous command execution processor should be in protected mode

; GDT data - 3*8 - 1 = 23 entries including null descriptor, start address is 32k
lgdt_data:
dw 17h
dd 8000h

hex_chr_buf:
db '0123456789ABCDEF'

gdt_test:
dq 0
