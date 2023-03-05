[bits 16]
[org 0100h]

[section .text]
start:

push bp
mov bp, sp

; reserving 512 bytes on stack
; for read buffer + space for locals
sub sp, 21ch

; read buffer pointer
mov bx, sp

; read(head=0, track=0, sector=1, count=1)
mov ah, READ_SECTORS
mov dh, 0
mov ch, 0
mov cl, 1
mov al, 1

; hdd 0
mov dl, HDD_1

int 13h

; reading first partition MBR offset in sectors
mov bx, sp
mov cx, [bx+01c6h]
; partition 1 MBR offset ( sector 0x3f )
mov [bp-PARTITION_1_MBR_OFFSET_VAR], cx

; get disk 0 geometry
mov ah, GET_DRIVE_PARAMETERS
int 13h

; disk_heads = disc_head_max + 1 ( = 16 )
inc dh
mov [bp-1], dh

; sectors per track ( = 63 )
mov al, cl
and al, 3fh
mov [bp-SECTORS_PER_TRACK_VAR], al

; sectors_per_cylinder = sectors_per_track x disk_heads ( === 1008 )
mul dh
mov [bp-8], ax

; disk tracks max ( = 15 )
mov ax, 0
mov ah, cl
and ah, c0h
mov cl, 6
shr ax, cl
mov al, ch
mov [bp-4], ax

; load first partition MBR using offset
; 0x7e00 MBR

; extract this code to special function get_chs(sector offset stored in ax)
; result will be returned in global buffer

; track_number = ( offset / sectors_per_cylinder )
mov ax, [bp-PARTITION_1_MBR_OFFSET_VAR]
mov dx, 0
mov cx, [bp-8]
div cx

; track_number = ax ( === 0 )
mov [bp-0ah], ax

; ( offset % sectors_per_cylinder ) / sectors_per_track
mov ax, dx
mov cl, [bp-SECTORS_PER_TRACK_VAR]
div cl

; head number = al
; sector number = ah


; read(head=al)
mov dh, al

; loading track number
mov bx, [bp-0ah]
mov cx, 8
; shifting track number to bh
shl bx, cl

; read_sector
mov cx, 0
; read(sector=ah+1)
mov cl, ah

; sectors are counting from 1
inc cx

; read(track=bh)
mov ch, bh

; read(count=1) MBR is 512 bytes <=> 1 sector
mov al, 1

; read buffer pointer
mov bx, sp

; reading hdd 1
mov dl, HDD_1

; read sectors function
mov ah, READ_SECTORS

int 13h

; load sectors per cluster ( byte offset 0x0d === 4 )

; number of FAT tables ( byte offset 0x10 === 2 )
mov cx, 0
mov si, sp
mov cl, [si+FAT_TABLES_COUNT_MBR_OFFSET]
; number of FAT sectors ( 2 bytes offset 0x16 === 6 )

mov ax, 0
; summing FAT sectors count x FAT tables count times 
root_dir_offset_loop: 
add ax, [si+FAT_SECTORS_COUNT_MBR_OFFSET]
loop root_dir_offset_loop

; adding MBR offset
add ax, [bp-PARTITION_1_MBR_OFFSET_VAR]

; + MBR size = 1 sector
inc ax

; number of root directory entries ( 2 bytes offset 0x11 === 512 ( 32 bytes each entry ) )
mov cx, [si+ROOT_DIR_ENTRIES_COUNT]

; calculating root directory table size in bytes
mov dx, cx
; each entry is 4 bytes long
shl dx, 1
shl dx, 1

; deallocating MBR buffer
add sp, 200h
; allocating root dicrectory table buffer
sub sp, dx

; searching for file with name KILL
file_search:


; calculate root directory size and load into stack allocated buffer
; search for loader.sys and determine it's first cluster offset
; also, read file size and how many iterations we need to read all it's clusters


mov ah, 04ch
mov al, cl
int 21h

[section .data]
PARTITION_1_MBR_OFFSET_VAR equ 6
SECTORS_PER_TRACK_VAR equ 2
READ_SECTORS equ 02h
HDD_1 equ 81h
GET_DRIVE_PARAMETERS equ 08h
FAT_TABLES_COUNT_MBR_OFFSET equ 10h
FAT_SECTORS_COUNT_MBR_OFFSET equ 16h
ROOT_DIR_ENTRIES_COUNT equ 11h
