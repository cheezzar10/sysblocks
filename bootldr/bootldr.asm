[bits 16]
[org 0100h]

[section .text]
start:

push bp
mov bp, sp

; reserving 512 bytes on stack
; for read buffer + space for locals
sub sp, 210h

; read buffer pointer
mov bx, sp

; read(head=0, track=0, sector=1, count=1)
mov ah, 02h
mov dh, 0
mov ch, 0
mov cl, 1
mov al, 1

; hdd 0
mov dl, 80h

int 13h

; reading first partition MBR offset in sectors
mov bx, sp
mov cx, [bx+01c6h]
; partition 1 MBR offset
mov [bp-6], cx

; get disk 0 geometry
mov ah, 08h
int 13h

; disk heads count
mov [bp-1], dh

; sectors per track count
mov al, cl
and al, 3fh
mov [bp-2], al

; disk tracks count
mov ax, 0
mov ah, cl
and ah, c0h
mov cl, 6
shr ax, cl
mov al, ch
mov [bp-4], ax

; load first partition MBR using offset

; load sectors per cluster ( byte offset 0x0d === 4 )
; number of FAT tables ( byte offset 0x10 === 2 )
; number of root directory entries ( 2 bytes offset 0x11 === 512 ( 32 bytes each entry ) )
; number of FAT sectors ( 2 bytes offset 0x16 === 136 )

; 0x2200 MBR
; 0x2400 FAT

; 136 sectors per FAT x 512 x 2 FAT copies = 0x22000

mov ah, 04ch
mov al, cl
int 21h
