[bits 16]
[org 7c00h]

; dos sample command
; nasm loader.asm -f bin -o loader.com
; after that you can 'dd' it to MBR

; mbr header structure
[section .data]

; short jmp to to bootstrap code
bstr_jmp: db 0ebh, 03ch, 90h

[section .text]
; here we'll load image to memory
; switch to protected mode and jump to 32 bit image
nop
