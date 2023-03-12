[bits 16]
[org 0100h]

[section .text]
start:

push bp
mov bp, sp

; allocating buffer on stack + local vars
sub sp, 21ch

; sector 14, head 1, track 0 - first root dir table entry

; read buffer pointer
mov bx, sp

; read(head=1, track=0, sector=14, count=1)
mov dh, 1
mov ch, 0
mov cl, 14
mov al, 1

mov dl, 81h

mov ah, 02h
int 13h

mov bx, sp

; remaining root directory entries counter initialization
mov byte [bp-2], ROOT_DIR_ENTRIES_PER_SECTOR

file_search_loop:

; clear direction flag, moving forward
cld

; pointer to the current directory entry
mov si, bx
; pointer to the file name
mov di, file_name

mov cx, file_name_len
repe cmpsb

je file_found

; going to the next directory entry
add bx, 20h

dec word [bp-2]
jnz file_search_loop

; 
jmp file_not_found

file_found:
mov ax, [bx+DIR_ENTRY_FILE_STARTING_CLUSTER_OFFSET]

mov ah, 04ch
int 21h

file_not_found:
mov ah, 04ch
mov al, 0
int 21h


[section .data]
file_name db "KILL       "
file_name_len equ $-file_name
ROOT_DIR_ENTRIES_PER_SECTOR equ 16
DIR_ENTRY_FILE_STARTING_CLUSTER_OFFSET equ 01ah
