tr		org	4300h
true:		equ	-1
false:		equ	not true


eof:		equ	1ah
dle:		equ	90h
bdos:		equ	4205h
buffer:		equ	4280h
fcb:		equ	4250h

begin:
hell:		lxi	h,0
		dad	sp
		shld	ccpstack
		lxi	sp,stack

		lhld	bdos+1
		mvi	l,0
		lxi	d,-1700h
		dad	d
		shld	topmem
		call	ilprt
		db	13,10,'USQ  Version 1.19     Dave Rand     07/28/1983',0
		mvi	c,25
		call	bdos
		sta	current
		xra	a		;default to no prompt
		sta	pract
		lda	buffer
		ora	a
		jnz	ok
					;if no filespec, print instructions
	
inst:		call	ilprt
		db	13,10,'Use: USQ afn [afn afn ...] [destination drive:]',0


		mvi	a,255		;show prompt mode active
		sta	pract

in1:		call	ilprt
		db	13,10,'*',0
		lxi	h,buffer
		mvi	m,120
		xchg
		mvi	c,10
		call	bdos
		lda	buffer+1
		ora	a
		jz	in1
		sta	buffer
		mov	e,a
		mvi	d,0
		lxi	h,buffer+2
		push	h
		dad	d
		mvi	m,0
		pop	h
		lxi	d,buffer+1
in2:		mov	a,m
		stax	d
		ora	a
		jz	ok
		call	convuc
		stax	d
		inx	h
		inx	d
		jmp	in2

convuc:		cpi	'a'
		rc
		cpi	'z'+1
		rnc
		ani	5fh
		ret


		
	


ok:
		lda	pract
		ora	a
		jz	nosel
		mvi	a,13
		call	bdos
		lda	current
		mov	e,a
		mvi	c,14
		call	bdos


nosel:		lxi	h,4280h
		lxi	d,locl
		lxi	b,80h
		call	ldir
		mvi	c,25
		call	bdos
		sta	current
		inr	a
		sta	destd

		lxi	d,locl+1
ex1:		call	non$blnk	;point to first valid char
		jz	inst		;wups... no char to be had!
mul1:		xchg
		shld	nxtchr
		lxi	h,0
		shld	max1

		lxi	h,filespecs	;point to begin of wildcard table

parse:		push	h
		call	make$fcb	;make FCB please!
		lda	fcb+1
		cpi	' '
		jnz	par2
		call	ilprt
		db	13,10,'Output drive = ',0
		lda	fcb
		sta	destd
		adi	'@'
		call	conout
		call	ilprt
		db	':',0
		jmp	par1
par2:		pop	h
		call	buildam		;build amb file table
		shld	lastmem
		push	h
		lhld	max1
		dad	d
		shld	max1
par1:		lhld	nxtchr
pl1:		mov	a,m
		cpi	' '
		inx	h
		jz	pl2
		ora	a
		jz	pl3
		jmp	pl1
pl2:		shld	nxtchr
		xchg
		call	non$blnk
pl3:		pop	h
		jnz	parse		;all done?

gt1:
					;Name ok, any wildcards match?
		lhld	max1
		mov	a,l
		ora	h
		jnz	cont		;yep, can continue
		call	errext
		db	13,10,'No file(s) found.',0




cont:
		lhld	lastmem
		shld	sob
		shld	eob
		xchg
		lhld	topmem
		mov	a,h
		sub	d
		mov	h,a
		mov	a,l
		sbb	e
		mov	l,a
;hl now has total memory free. Divide in half.
		xra	a
		mov	a,h
		rar
		mov	h,a
		mov	a,l
		rar
		mov	l,a
;see if enuf memory.
		dcr	h
		mov	a,h
		ora	a
		jnz	memok
		call	errext
		db	13,10,13,10,'Out of memory. Use more specific filenames.',0

memok:		xchg
		lhld	lastmem
		dad	d
		shld	endmem
		inr	h
		inr	h
		mvi	l,0
		shld	sob1
		shld	sob1a	
		lhld	topmem
		shld	eob1

main:		lxi	h,filespecs

main1:		lxi	d,ifcb
		lxi	b,12
		call	ldir
		push	h
		push	d
		pop	h
		inx	d
		mvi	m,0
		lxi	b,38-13
		call	ldir
		lxi	d,ifcb
		mvi	c,15
		call	bdos
		inr	a
		jz	mainr
sysok:		call	ilprt
		db	13,10,0
		call	pfcb
		lhld	lastmem
		shld	sob
		shld	eob
		push	h
		call	getw
		lxi	d,0ff76h
		call	cmpdehl
		pop	h
		jz	usq
		call	ilprt
		db	' is not a squeezed file.',13,10,0
mainr:		lxi	sp,stack-2
		lhld	max1
		dcx	h
		shld	max1
		mov	a,h
		ora	l
		pop	h
		jnz	main1
		jmp	usq7


;this is start of baseline USQ code

usq:		xra	a		;force init char read
		sta	numlft
		sta	rcnt		;and zero repeats
usq1:		call	getw		;get cksum, and store
		shld	filecrc
		call	ilprt
		db	' -> ',0
		lxi	h,buffer	;get name of orig. file,
usq2:		push	h
		call	get1		;display, and store it
		pop	h		;for filename parse
		push	psw
		call	convuc
		mov	b,a
		pop	psw
		mov	a,b
		mov	m,a
		jnz	mainr
		ora	a
		jz	usq3
		push	h
		call	conout
		pop	h
		inx	h
		jmp	usq2

usq3:		lxi	h,buffer		;parse orig. name from
		shld	nxtchr			;buffer. Create FCB
		call	make$fcb
		lxi	h,fcb
		lxi	d,dfcb
		lxi	b,1+8+3
		call	ldir
		lda	destd
		sta	dfcb
		lxi	h,dfcb+1+8+3
		lxi	d,dfcb+1+8+3+1
		lxi	b,38-13
		mvi	m,0
		call	ldir
		lxi	d,dfcb
		push	d
		mvi	c,19
		call	bdos
		pop	d
		mvi	c,22
		call	bdos
		inr	a
		jnz	usq3a
		call	errext
		db	13,10,'No directory space. Aborting.',0
usq3a:		call	getw
		shld	numvals
		lxi	d,258
		call	cmpdehl
		jc	usq3b
		call	errext
		db	13,10,'Files has illegal decode size. Aborting.',0
usq3b:		lxi	d,table
usq4:		shld	max
		mov	a,h
		ora	l
		jz	usq5
		push	d
		call	getw
		pop	d
		xchg
		mov	m,e
		inx	h
		mov	m,d
		inx	h
		push	h
		call	getw
		xchg
		pop	h
		mov	m,e
		inx	h
		mov	m,d
		inx	h
		xchg
		lhld	max
		dcx	h
		jmp	usq4

usq5:		lxi	h,0
usq6:		push	h
		call	getnxt
		pop	h
		jnz	usq8
		mov	e,a
		mvi	d,0
		dad	d
		push	h
		call	put1
		pop	h
		jmp	usq6

usq8:		xchg
		lhld	filecrc
		call	cmpdehl
		push	psw
		call	flush
		lxi	d,dfcb
		mvi	c,16
		call	bdos
		inr	a
		jnz	usq9
		call	errext
		db	13,10,'Close failed...',0

usq9:		pop	psw
		jz	mainr
		call	ilprt
		db	13,10,'ERROR - Checksum error in file ',0
		call	pfcb
		
usq7:		lxi	sp,stack
		lda	pract
		ora	a
		jnz	in1

		lxi	sp,0
ccpstack:	equ	$-2
		ret

errext:		pop	h
		mov	a,m
		ora	a
		jz	usq7
		inx	h
		push	h
		call	conout
		jmp	errext

conout:		ani	127
		mov	e,a
		mvi	c,2
		call	bdos
		ret


cmpdehl:	mov	a,h
		cmp	d
		rnz
		mov	a,l
		cmp	e
		ret

ilprt:		pop	h
		mov	a,m
		ora	a
		inx	h
		push	h
		rz
		call	conout
		jmp	ilprt

get1:		lhld	eob
		xchg
		lhld	sob
		call	cmpdehl
		jz	get1r
		mov	a,m
		inx	h
		shld	sob
		cmp	a
		ret

get1r:		lhld	lastmem
		shld	sob
		shld	eob
get1r1:		push	h
		xchg
		mvi	c,26
		call	bdos
		lxi	d,ifcb
		mvi	c,20
		call	bdos
		pop	h
		ora	a
		jnz	get1r2
		lxi	d,128
		dad	d
		xchg
		lhld	endmem
		call	cmpdehl
		xchg
		jnc	get1r1
get1r2:		shld	eob
		xchg
		lhld	sob
		call	cmpdehl
		jnz	get1
		mvi	a,255
		ora	a
		ret



put1:		mov	c,a
		lhld	eob1
		xchg
		lhld	sob1
		call	cmpdehl
		jz	put1s
		mov	m,c
		inx	h
		shld	sob1
		ret

put1s:		push	b
		call	flush
		pop	b
		mov	a,c
		jmp	put1

flush:		lhld	sob1a
		xchg
		lhld	sob1
		call	cmpdehl
		rz
		xchg
put1sa:		push	h
		xchg
		mvi	c,26
		call	bdos
		mvi	c,21
		lxi	d,dfcb
		call	bdos
		ora	a
		jnz	put1sc
		pop	h
		lxi	d,128
		dad	d
		xchg
		lhld	sob1
		xchg
		call	cmpdehl
		jc	put1sa
		lhld	sob1a
		shld	sob1
		ret


put1sc:		call	errext
		db	13,10,'Disk full. Aborting.',0


getw:		call	get1
		jnz	badr
		push	psw
		call	get1
		jnz	badr
		mov	h,a
		pop	psw
		mov	l,a
		ret

badr:		call	ilprt
		db	13,10,'Premature EOF on file... aborted.',0
		jmp	mainr

getnxt:		lda	rcnt		;see if in the middle of
		ora	a		;repeat sequence...
		jz	getn7
		dcr	a
		sta	rcnt
		lda	last
		cmp	a
		ret
getn7:		call	getn4
		cpi	dle
		jnz	getn5
		call	getn4
		ora	a
		jnz	getn6
		mvi	a,dle		;dle is encoded as dle,0
		cmp	a
		ret
getn6:		dcr	a
		dcr	a
		sta	rcnt
		lda	last
		cmp	a
		ret
getn5:		sta	last
		cmp	a
		ret


getn4:		lxi	d,0		;pointer @ sot
		lda	char
		mov	c,a
getn1:		lda	numlft
		ora	a
		jnz	getn2
		push	d
		call	get1
		jnz	badr
		pop	d
		mov	c,a
		mvi	a,8
getn2:		dcr	a
		sta	numlft
		mov	a,c
		rrc
		mov	c,a
		lxi	h,table
		jnc	getn3
		inx	h
		inx	h		;add 2 to point to right node
getn3:		dad	d
		dad	d
		dad	d
		dad	d		;ok.. pointing close to right plc..
		mov	e,m
		inx	h
		mov	d,m
		mov	a,d
		ani	128
		jz	getn1
		mov	a,c
		sta	char
		mov	a,d
		cpi	254		;is special eof?
		mvi	a,eof
		jz	geteof		;yup
		mov	a,e
		cma
		cmp	a
		ret

geteof:		pop	h
		ora	a
		ret


;end of baseline USQ code

buildam:	equ	$
		lxi	d,0		;none found yet
		push	d
		push	h
		lda	fcb
		ora	a
		jz	build1
		mov	e,a
		dcr	e
		mvi	c,14
		call	bdos
build1:
		mvi	c,17
		lxi	d,fcb
		call	bdos
		pop	h
		pop	d
		inr	a		;any found?
		jnz	loop
buildr:		push	h
		push	d
		lda	current
		mov	e,a
		mvi	c,14
		call	bdos
		pop	d
		pop	h
		ret

loop:		inx	d
		push	d
		push	h
		dcr	a
		add	a
		add	a
		add	a
		add	a
		add	a
		lxi	h,buffer
		mov	e,a
		mvi	d,0
		dad	d
		pop	d
		inx	h
		lda	fcb
		stax	d
		inx	d
		mvi	b,11
ldir2:		mov	a,m
		stax	d
		inx	h
		inx	d
		dcr	b
		jnz	ldir2
		xchg
		push	h
		mvi	c,18
		lxi	d,fcb
		call	bdos
		pop	h
		pop	d
		inr	a
		jnz	loop
		jmp	buildr


pfcb:		lda	ifcb
		ora	a
		jz	print1
		mov	b,a		;New!
		lda	current
		inr	a
		cmp	b
		jz	print1
		mov	a,b		;New...
		adi	'A'-1
		call	conout
		mvi	a,':'
		call	conout
print1:		lxi	h,ifcb+1
		mvi	c,8
print1a:	push	h
		push	b
		mov	a,m
		cpi	' '
		jz	print1b
		call	conout
print1b:	pop	b
		pop	h
		inx	h
		dcr	c
		jnz	print1a
		mvi	a,'.'
		call	conout
		lxi	h,ifcb+1+8
		mvi	c,3
print2a:	push	h
		push	b
		mov	a,m
		cpi	' '
		jz	print2b
		call	conout
print2b:	pop	b
		pop	h
		inx	h
		dcr	c
		jnz	print2a
		ret

MAKE$FCB:
;
;Create a FCB in FCB
;'NEXT$CHAR' is saved pointing to the next character
;following the string set up as a file NAME.TYPE.
;
;For example, the SAVE command finds the ascii string
;corresponding to the ntmber of decimal records to write
;as a file name in the first 16 bytes of the fcb, and
;the name of the file to created in the second 16 bytes
;of the fcb.
;
MAKE1$FCB:
	LXI	H,FCB		;point to ccp's fcb
	PUSH	H		;save char pointer once
	LHLD	NXTCHR		;get pointer to next char in buffer
	XCHG			;put buffer pointer in <DE>
	CALL	NON$BLNK	;get next non-blank char in acc
	POP	H
	LDAX	D
	ORA	A
	JZ	NO$DRV
	SBI	'@'
	MOV	B,A
	INX	D
	LDAX	D
	CPI	':'
	JZ	YES$DRV
	DCX	D
NO$DRV: LDA	current
	inr	a		;@1.02
	MOV	M,A
	JMP	GET$NAME
;
YES$DRV:
	MOV	M,b
	INX	D
;
;The next 8 characters in the CCP$FCB are to be a file
;name.	Transfer the contents of the CON$BUF, checking
;for reserved characters and ambigious name char ('*' or '?')
;filling with blanks or '?' as required.
;
GET$NAME:
	MVI	B,8
GET1$NAME:
	CALL	TEST4RES
	JZ	FIL$SPC
	INX	H
	CPI	'*'
	JNZ	NOT$AMB
	MVI	M,3FH
	JMP	KEEP$CNT
;
NOT$AMB:
	MOV	M,A
	INX	D
KEEP$CNT:
	DCR	B
	JNZ	GET1$NAME
FIND$RES:
	CALL	TEST4RES
	JZ	PUT$TYPE
	INX	D
	JMP	FIND$RES
;
FIL$SPC:
	INX	H
	MVI	M,' '
	DCR	B
	JNZ	FIL$SPC
;
;The next three characters in the CCP$FCB are to be the
;file type.  Transfer the contents of CON$BUF checking
;for reserved characters and ambigious characters ('*' or '?')
;Fill with '?'s as required.
;
PUT$TYPE:
	MVI	B,3
	CPI	'.'
	JNZ	FIL2$SPC
	INX	D
PUT2$TYPE:
	CALL	TEST4RES
	JZ	FIL2$SPC
	INX	H
	CPI	'*'
	JNZ	XFER$TYPE
	MVI	M,'?'
	JMP	KEEP2$CNT
;
XFER$TYPE:
	MOV	M,A
	INX	D
KEEP2$CNT:
	DCR	B
	JNZ	PUT2$TYPE
;
;We have a FILENAME.TYPE, so now find the next reserved
;character in the command string so we can save NEXT$CHAR
;below
;
FIND1$RES:
	CALL	TEST4RES
	JZ	FILL$NULL
	INX	D
	JMP	FIND1$RES
;
FIL2$SPC:
	INX	H
	MVI	M,' '
	DCR	B
	JNZ	FIL2$SPC
;
;Set the file extent (byte 12 of fcb) and the
;unused bytes (13 and 14) of the fcb to zero
;
FILL$NULL:
	MVI	B,3
FILL1$NULL:
	INX	H
	MVI	M,0
	DCR	B
	JNZ	FILL1$NULL
;
;We are almost finished.  Save pointer of the next character
;in the console buffer, count the number of ambigious char's
;in the filename.type, and return with the count in acc and
;the flags set
;
	XCHG
	SHLD	NXTCHR
	RET

;
;Test char at <DE> for reserved characters 'SPACE',
;'EQUALS', 'UNDERLINE', 'PERIOD', 'COLON', 'SEMI-COLON',
;'LEFT-ARROW', 'RIGHT-ARROW', and return with zero set,
;if found.  If the character is less than an ascii SPACE,
;and exit is made to the ECHO$BUF routine which will
;print the error prompt and echo the buffer
;
TEST4RES:
	LDAX	D		;get (DE) in acc
	ORA	A		;set the flags
	RZ			;get back if null
	CPI	' '		;is it less than a SPACE?
	RZ			;if ' ', then get back
	CPI	'='
	RZ			;if '=', get back
	CPI	'_'
	RZ			;if '_', get back
	CPI	'.'
	RZ			;if '.', get back
	CPI	':'
	RZ			;if ':', get back
	CPI	';'
	RZ			;if ';', get back
	CPI	'<'
	RZ			;if '<', get back
	CPI	'>'
	Ret			;if '>', get back
;
;Search the character string pointed by <DE> until
;a non-blank char or null is found.  If a null is
;found, return with ZERO flag set.  Otherwise return
;with the char in the acc and <DE> pointing to it.
;(null is placed at end of command string by convert
;routine)
;
NON$BLNK:
	LDAX	D		;get next char
	ORA	A		;set flags
	RZ			;get back if null
	CPI	' '		;is it a space?
	RNZ			;no, then get back
	INX	D		;bump the pointer
	JMP	NON$BLNK	;loop

ldir:		mov	a,m
		stax	d
		inx	h
		inx	d
		dcx	b
		mov	a,b
		ora	c
		jnz	ldir
		ret


numvals:	dw	0
max:		dw	0
numlft:		db	0
char:		db	0
last:		db	0
rcnt:		db	0
lastmem:	dw	0
max1:		dw	0
nxtchr:		dw	0
current:	db	0
endmem:		dw	0
topmem:		dw	0
sob:		dw	0
eob:		dw	0
sob1:		dw	0
sob1a:		dw	0
eob1:		dw	0
destd:		db	0
pract:		db	0
filecrc:	dw	0

ifcb:		ds	40
dfcb:		ds	40

locl:		ds	80h

		ds	100
stack:		equ	$
table:		ds	258*4
filespecs:	equ	$

		end	begin
