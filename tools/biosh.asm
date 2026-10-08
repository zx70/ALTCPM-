
	maclib bds
	maclib cmac

	direct
	define biosh
	enddir


;
; Bios-h:
;
;	biosh(n,c)
;
; Call to bios jump table routine n, with BC set to c. n=0 for boot,
; n=1 for wboot, n=2 for const, etc.
; Exit with value in HL
;
	prelude	biosh
	
	call arghak	
	push b
	lhld base+1	;get addr of jump table + 3
	dcx h		;set to addr of first jump
	dcx h
	dcx h
	lda arg1	;get function number (1-85)
	mov b,a		;multiply by 3
	add a
	add b
	mov e,a		;put in DE
	mvi d,0
	dad d		;add to base of jump table
	push h		;and save for later
	lhld arg2	;get value to be put in BC
	mov b,h		;and put it there
	mov c,l
	reloc <lxi h,>,retadd	;where call to bios will return to
	xthl		;get address of vector in HL
	pchl		;and go to it...
retadd:	       	pop	b	;all done. Leave return value in HL
	ret		;and return to caller

	postlude biosh


