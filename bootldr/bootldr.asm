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
mov [bp-DISK_HEADS_COUNT_VAR], dh

; sectors per track ( = 63 )
mov al, cl
and al, 3fh
mov [bp-SECTORS_PER_TRACK_VAR], al

; sectors_per_cylinder = sectors_per_track x disk_heads ( === 1008 )
mul dh
mov [bp-SECTORS_PER_CYLINDER_VAR], ax

; disk tracks max ( = 15 )
mov ax, 0
mov ah, cl
and ah, 0c0h
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
call get_chs

; read(head=al)
mov dh, [chs_head]

; loading track number
mov bx, [chs_track]
mov cx, 8
; shifting track number to bh
shl bx, cl

; read_sector
mov cx, 0
; read(sector=ah+1)
mov cl, [chs_sector]
inc cx

; read(track=bh)
mov ch, bh

; read(count=1) MBR is 512 bytes => 1 sector
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

; adding MBR offset ( 2 x 0x6 + 0x3f = 0x4c )
add ax, [bp-PARTITION_1_MBR_OFFSET_VAR]

; + MBR size = 1 sector
inc ax

; calculating root directory entries table CHS
call get_chs

; number of root directory entries ( 2 bytes offset 0x11 === 512 ( 32 bytes each entry ) )
mov dx, [si+ROOT_DIR_ENTRIES_COUNT_MBR_OFFSET]
mov [bp-ROOT_DIR_ENTRIES_COUNT_VAR], dx

; root directory table size in sectors
; root_dir_entries_count x 32 / 512 it's the same as root_dir_entries_count >> 7
mov cx, 4
shr dx, cl
mov [bp-ROOT_DIR_TABLE_SIZE_IN_SECTORS_VAR], dl

; setting current root directory table sector index
mov [bp-ROOT_DIR_TABLE_CURRENT_SECTOR_INDEX_VAR], dl

; keeping current root dir entries table sector in var
; dec [bp-current sector var]

; reading root directory table
; read(head=chs_head, track=chs_track, sector=chs_sector, count=dl)

mov dh, [chs_head]

mov cx, 0
mov cl, [chs_sector]
; sectors count starts from 1
inc cx

; chs_track is 2 bytes long and high byte low 2 bits should be combined with starting sector number ( cl )
mov ch, [chs_track]

; reading directory table by 1 sector
mov al, 1
mov dl, HDD_1

; read buffer allocated on stack
mov bx, sp

root_dir_table_read_loop:
; reading current root directory table sector
mov ah, READ_SECTORS
int 13h

; searching for file with the given name
; using si as offset from 0x0 to 512 - 32
; current root dir table entry index ( reversed, ROOT_DIR_ENTRIES_PER_SECTOR - first entry )
mov word [bp-ROOT_DIR_TABLE_CURRENT_ENTRY_INDEX_VAR], ROOT_DIR_ENTRIES_PER_SECTOR

file_search_loop:
; clearing direction flag, going forward
cld

; pointer to the current directory entry
mov si, bx
; pointer to the file name
mov di, FILE_NAME

; comparing
mov cx, FILE_NAME_LENGTH
repe cmpsb

; exiting from file search/root dicrectory sector loading loop
je file_found

; going to the next directory entry
add bx, 20h

; decrementing current root dir table entry index
dec word [bp-ROOT_DIR_TABLE_CURRENT_ENTRY_INDEX_VAR]

; end of file search loop in current root dir table sector
jnz file_search_loop


; indexes go down (3,2,1,0) , but sectors go up (1,2,3,4)
dec byte [bp-ROOT_DIR_TABLE_CURRENT_SECTOR_INDEX_VAR]

; end of root dir table sectors reading loop
jnz root_dir_table_read_loop

; if we are here, file not found
file_not_found:
mov ah, EXIT
mov al, 0
int 21h

; read using loop, iterate through table sectors, loading them one by one
; checking for sector/head limits crossing


; calculate root directory size and load into stack allocated buffer
; search for loader.sys and determine it's first cluster offset
; also, read file size and how many iterations we need to read all it's clusters

file_found:
mov ax, [bx+ROOT_DIR_ENTRY_FILE_STARTING_CLUSTER_OFFSET]

mov ah, EXIT
int 21h

; get_chs(ax = global sector offset) returns result in global structure
get_chs:
mov dx, 0
mov cx, [bp-SECTORS_PER_CYLINDER_VAR]
div cx

; saving track number
mov [chs_track], ax

; ( offset % sectors_per_cylinder ) / sectors_per_track
mov ax, dx
mov cl, [bp-SECTORS_PER_TRACK_VAR]
div cl

; head number = al
mov [chs_head], al
; sector number = ah
mov [chs_sector], ah

ret

[section .data]
; get_chs function return value will be stored here
chs_track dw 0
chs_head db 0
chs_sector db 0

; local variables on stack frame
DISK_HEADS_COUNT_VAR equ 1
SECTORS_PER_TRACK_VAR equ 2
DISK_TRACKS_MAX_VAR equ 4
PARTITION_1_MBR_OFFSET_VAR equ 6
SECTORS_PER_CYLINDER_VAR equ 8
ROOT_DIR_ENTRIES_COUNT_VAR equ 10
ROOT_DIR_TABLE_SIZE_IN_SECTORS_VAR equ 11
ROOT_DIR_TABLE_CURRENT_SECTOR_INDEX_VAR equ 12
ROOT_DIR_TABLE_CURRENT_ENTRY_INDEX_VAR equ 14

READ_SECTORS equ 02h
EXIT equ 04ch
HDD_1 equ 81h
GET_DRIVE_PARAMETERS equ 08h
FAT_TABLES_COUNT_MBR_OFFSET equ 10h
FAT_SECTORS_COUNT_MBR_OFFSET equ 16h
ROOT_DIR_ENTRIES_COUNT_MBR_OFFSET equ 11h
ROOT_DIR_ENTRIES_PER_SECTOR equ 16
ROOT_DIR_ENTRY_FILE_STARTING_CLUSTER_OFFSET equ 01ah

FILE_NAME db "KILL       "
FILE_NAME_LENGTH equ $-FILE_NAME
