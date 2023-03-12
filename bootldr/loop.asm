[bits 16]
[org 0100h]

[section .text]
start:

push bp
mov bp, sp

; iterations counter
push word 4

mov cx, 0

root_dir_table_sectors_loop:
inc cx
dec [bp-2]
jnz root_dir_table_sectors_loop

mov ah, 04ch
mov al, cl
int 21h
