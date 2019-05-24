[bits 16]
[org 7c3eh]

[section .text]

; clearing screen
mov ax, 0600h
mov bh, 7
mov cx, 0
mov dx, 184fh
int 10h

; es register init required for image read buf
mov ax, 0
mov es, ax

; loading image right at the 32kb origin

; requesting read service 02h and reading 16 sectors
mov ax, 0210h
; loading at 32kb 
mov bx, 8000h
; selecting track 0 and sector 2
mov cx, 0002h
mov dx, 0000h

; reading binary image
int 13h

; displaying @ bofore switching to protected mode
mov ax, 0b800h
mov es, ax

mov ax, 0740h
mov di, 0
mov [es:di], ax

; disabling iterrupts
cli

; loading global descriptor table
lgdt [lgdt_data]

; set protection flag
mov eax, cr0
or eax, 1
mov cr0, eax

[section .data]

init_far_jmp:
; encoding far jmp directly
db 0eah
; tables are on 32kb + 4kb image code section alignment
dw 9000h
; code segment selector
dw 08h

; we should be in protected mode now

; GDT data - 3*8 - 1 = 23 entries including null descriptor, start address is 32k
lgdt_data:
dw 17h
dd 8000h

hex_chr_buf:
db '0123456789ABCDEF'

gdt_test:
dq 0
