ORG  0x7C00
BITS 16

jmp short main
nop

bdb_oem:					db 'MSWIN4.1'
bdb_bytes_per_sector:		dw 512
bdb_sectors_per_cluster:	db 1
bdb_reserved_sectors:		dw 1
bdb_fat_count:				db 2
bdb_dir_entries_count:		dw 0x0e0
bdb_total_sectors:			dw 2880
bdb_media_descriptor_type:	db 0x0f0
bdb_sectors_per_fat:		dw 9
bdb_sectors_per_track:		dw 18
bdb_heads:					dw 2
bdb_hidden_sectors:			dd 0
bdb_large_sector_count:		dd 0

ebr_drive_number:			db 0												; extended boot record
							db 0
ebr_signature:				db 0x29
ebr_volume_id:				db 0x12, 0x34, 0x56, 0x78
ebr_volume_label:			db 'ARDONIUM/OS'
ebr_system_id:				db 'FAT12   '

main:
	xor  ax, ax																	; mov  ax, 0
	mov  ds, ax
	mov  es, ax
	mov  ss, ax

	mov  sp, 0x7c00

	mov  [ebr_drive_number], dl
	mov  ax, 1
	mov  cl, 1
	mov  bx, 0x7e00
	call disk_read

	mov  si, boot_msg
	call print
	
	hlt

halt:
	jmp  halt

; input: LBA index in ax
; output:
;     cx [bits 0-5]:  sector number
;     cx [bits 6-15]: cylinder
;	  dh: head
lba_to_chs:
	push ax
	push dx

	xor  dx, dx
	div  word [bdb_sectors_per_track]											; sector -> (LBA % (sectors per track)) + 1
	inc  dx 																	; sector
	mov  cx, dx

	xor  dx, dx
	div  word [bdb_heads]														; head -> (LBA / (sectors per track)) % (number of heads)
	mov  dh, dl																	; head
	mov  ch, al
	shl  ah, 6
	or   cl, ah																	; cylinder -> (LBA / (sectors per track)) / (number of heads)

	pop  ax
	mov  dl, al
	pop  ax

disk_read:
	push ax
	push bx
	push cx
	push dx
	push di

	call lba_to_chs

	mov  ah, 0x02
	mov  di, 3																	; counter

retry:
	stc
	int  0x13
	jnc  done_read

	call disk_reset

	dec  di
	test di, di
	jnz  retry

fail_read:
	mov  si, read_failure_msg
	call print
	hlt
	jmp halt

disk_reset:
	pusha
	mov  ah, 0
	stc
	int  0x13
	jc   fail_read
	popa
	ret

done_read:
	pop  di
	pop  dx
	pop  cx
	pop  bx
	pop  ax

	ret

print:
	push si
	push ax
	push bx

print_loop:
	lodsb
	or   al, al
	jz   done_print

	mov  ah, 0x0e
	mov  bh, 0
	int  0x10

	jmp  print_loop

done_print:
	pop  bx
	pop  ax
	pop  si
	ret

boot_msg: 					db "Loading...", 0x0d, 10, 0
read_failure_msg:			db "Disk read failed!", 0x0d, 10, 0

times 510 - ($ - $$) 		db 0												; boot signature
dw 0x0aa55

