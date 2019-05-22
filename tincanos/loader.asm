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

; disabling iterrupts
cli

; may be NMI interrupts should be masked too

; loading global descriptor table
lgdt [lgdt_data]

; set protection flag
mov eax, cr0
or eax, 1
mov cr0, eax

; interrupt vectors can be loaded after switch to protected mode

[section .data]

init_far_jmp:
; encoding far jmp directly
db 0ebh
; tables are on 32kb + 4kb image code section alignment
dw 9000h
; code segment selector
dw 08h

; after previous command execution processor should be in protected mode

; GDT data - 3 entries including null descriptor, start address is 32k
lgdt_data:
dw 3
dd 8000h
