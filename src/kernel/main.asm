ORG  0x7C00
BITS 16

main:
	xor  ax, ax																	; mov  ax, 0
	mov  ds, ax
	mov  es, ax
	mov  ss, ax

	mov  sp, 0x7c00
	mov  si, boot_msg
	call print
	
	hlt

halt:
	jmp  halt

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

boot_msg:
	db "Welcome to ardonium/OS v0.01", 0x0d, 10, 0

times 510 - ($ - $$) db 0														; boot signature
dw 0x0aa55

