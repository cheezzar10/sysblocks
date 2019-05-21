[bits 16]
[org 7c00h]

; dos sample command
; nasm loader.asm -f bin -o loader.com
; after that you can 'dd' it to MBR
; take a node that com file format assume 8 byte header at the start and 
; we shoud take this into account when manupulating with data

; mbr header structure
[section .data]

; short jmp to to bootstrap code
bstr_jmp: db 0ebh, 03ch, 90h
; OS name and version which was used for filesystem creation
os_ver: db 'osnamver'
; 512 bytes per sector
bts_per_sec: dw 200h
; sectors per cluster
sec_per_clst: db 1
; reserved sectors count
res_sec_cnt: dw 1
; number of FAT copies
fat_copies_count: db 2
; number of root directory entries = 224
; this number should be multiplied on 32 to calculate data offset location
root_dir_entries: dw 0e0h
; total sectors on disc = 2880
total_sectors: dw 0b40h
medium_type: db 0f0h
; how many sectors reserved for each FAT
sec_per_fat: dw 09h
sec_per_track: dw 12h
; drive heads count
heads_cnt: dw 2
; hidden sectors count
hidded_sec_cnt: dw 0, 0
; logical volume sectors count - for HDD only
log_vol_sec_cnt: dw 0, 0
; physical drive number
drive_num: db 0
; reserved byte
res_bt: db 0
; boot signature record
boot_sig: db 29h
; binary volume id
vol_id: db 0e5h, 19h, 0e8h, 3bh
; 10 byte volume label
vol_lbl: db 'TINCANOS  '
; 8 bytes reserved block
res_blk: db ' FAT12   '

[section .text]
; here we'll load image to memory
; switch to protected mode and jump to 32 bit image

; encoding far jmp directly
db 0ebh
; tables are on 32mb boundary, fix addr cause init code is higher in memory
dw 8000h
; code segment selector
dw 08h
