	maclib bds
	maclib cmac

	direct
	define cfsize
	enddir

;
; cfsize:
; 	cfsize(fd)
;
; Compute size of file, but leave random-record field at original value.
;

	prelude	cfsize

	call	ma1toh
	call	fgfcb
	jnc	cfsiz2
	mvi	a,7	;"bad fd" error
;	sta	errnum
	jmp	error

cfsiz2:	push	b	;save BC
	push 	h	;save fcb address
	call	ma3toh	;set user area
	call	fgfd	;get pointer to fd table entry

	mov	a,m
;	call	setusr
	inx	h
	shld	tmp2	;save pointer to max sector value

	pop	d	;restore fcb address into DE
	lxi	h,33	;get to random record field
	dad	d
	push	h	;save ptr to random record field for after BDOS call

	mov	a,m
	inx	h
	mov	h,m
	mov	l,a	;HL = current setting
	push	h	;save current value of random record field

	;mvi	c,cfsizc	;compute file size
	mvi	c,35	;compute file size
	call	bdos
	pop	b	;pop old random record value into BC
	pop	h	;get pointer to random record field

	mov	e,m	;get end-of-file sector number into DE
	inx	h
	mov	d,m

	mov	m,b	;restore original value
	dcx	h
	mov	m,c

	lhld	tmp2	;get pointer to fd table max sector value
	push	h	;save ptr to max value
	mov	a,m	;get max sector value in HL
	inx	h
	mov	h,m
	mov	l,a	;now old max in HL, fsize value in DE
	call	cmphd	;is old max < current fsize?
	jnc	cfsiz3	;if not, just return old max as current max
	xthl		;get back pointer to old max value
	mov	m,e	;update with new fsize value
	inx	h
	mov	m,d
	xchg		;put end-of-file sector number in HL for return

cfsiz3:	pop	d	;clean up stack
;	call	rstusr	;reset user area
	pop	b
	ret

cmphd:	mov a,h
	cmp d
	rnz
	mov a,l
	cmp e
	ret

	postlude cfsize
