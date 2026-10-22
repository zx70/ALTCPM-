; UNLOAD
;
; Utility to convert .COM format to .HEX format.
;
; by P. Swayne, HUG    24-Jul-81
;	Adapted from IHEX from 885-1089

BDOS	EQU	4205h

	ORG	4300H
START	LXI	H,0
	DAD	SP		;GET OLD STACK LOCATION
	SHLD	OLDSTK		;STORE IT
	LXI	SP,STACK
	MVI	C,9
	LXI	D,425CH		;FCB
	LXI	H,DFCB		;DESTINATION FCB
MFCB	LDAX	D
	INX	D
	MOV	M,A
	INX	H
	DCR	C
	JNZ	MFCB
	LDA	65H		;CHECK TYPE
	CPI	20H		;IS THERE ONE?
	JNZ	GOTTYP		;IF SO, CONTINUE
	LXI	H,4F43H		;"CO"
	SHLD	65H
	MVI	A,'M'
	STA	67H		;STORE "COM" AS TYPE
GOTTYP	LXI	D,425CH		;FCB
	MVI	C,15		;OPEN
	CALL	BDOS		;OPEN INPUT FILE
	INR	A
	JNZ	GDFILE		;OPEN OK
	MVI	C,9
	LXI	D,NOINFL
	CALL	BDOS
	JMP	EXIT		;RETURN TO CP/M
NOINFL	DB	0DH,0AH,'Can''t find input file.$'
GDFILE	LXI	D,DFCB
	MVI	C,19		;DELETE
	CALL	BDOS
	LXI	D,DFCB
	MVI	C,22
	CALL	BDOS		;OPEN OUTPUT FILE
	CPI	0FFH		;OK?
	JNZ	GDOUT
	LXI	D,NODIR
	MVI	C,9
	CALL	BDOS
	JMP	4200h
NODIR	DB	0DH,0AH,'No directory space.$'
GDOUT	EQU	$
; Read the first sector.

OPEN01	CALL	READS
	CALL	CWBUFF		;Clear Write Buffer
	LXI	H,4300H
	SHLD	DBFWA		;SET UP OBJ FWA
	XRA	A
	STA	EOFFLG		;CLEAR EOF FLAG
; Start a hex record.

TRAN	XRA	A
	STA	CHKSUM
	LHLD	WPTR
	MVI	M,0DH		;CR
	INX	H
	CALL	TWPTR
	LHLD	WPTR
	MVI	M,0AH		;LF
	INX	H
	CALL	TWPTR
	LHLD	WPTR
	MVI	M,':'
	INX	H
	CALL	TWPTR		;Update, test WPTR
; Calculate and output record length.

CHEOF	LDA	EOFFLG
	ORA	A		;AT END OF FILE?
	JNZ	TRAN04		;IF SO, FINISH
	CALL	GET16		;GET 16 BYTES
	LDA	ZROFLG
	ORA	A		;GOT ALL ZEROS?
	JZ	CHEOF		;SHOULDN'T, SO CHECK EOF
	MVI	A,16
TRAN01	PUSH	PSW
	CALL	MBYTE		;Output length
; Output object code address pointer.

	LHLD	DBFWA
	PUSH	H
	MOV	A,H
	CALL	MBYTE		;Output msb's
	POP	H
	MOV	A,L
	CALL	MBYTE		;and lsb's
; Show "data" type.

	XRA	A
	CALL	MBYTE
; Output some data bytes.

	LXI	H,BUFF16
TRAN02	MOV	A,M
	PUSH	H
	CALL	MBYTE		;Output a byte
	LHLD	DBFWA
	INX	H
	SHLD	DBFWA		;Increment file address
	POP	H
	INX	H
; Check byte count.

	POP	PSW
	DCR	A
	JZ	TRAN03		;We're done with this rcd
	PUSH	PSW
	JMP	TRAN02		;Loop for another
; Finish up the data record with checksum.

TRAN03	LDA	CHKSUM
	CALL	MBYTE		;Output the checksum
	JMP	TRAN		;and send another record
; Output the ending record.

TRAN04	XRA	A
	CALL	MBYTE		;Show "last record"
	MVI	A,1
	CALL	MBYTE		;Output start addr msb's
	XRA	A
	CALL	MBYTE		;and lsb's
	MVI	A,1
	CALL	MBYTE		;Show end-of-file
	LDA	CHKSUM
	CALL	MBYTE		;and checksum
	CNC	TWPTR1		;Write last sctr if necessary
; Close the files and see if there is another task.

	LXI	D,COMPL
	MVI	C,9
	CALL	BDOS
	LXI	D,DFCB
	MVI	C,16		;CLOSE
	CALL	BDOS		;CLOSE OUTPUT FILE
	JMP	EXIT		;RETURN TO CP/M
COMPL	DB	0DH,0AH,'Conversion complete.$'
; Subroutine to Move one BYTE. Adds to checksum and
; converts to hex.
;	Input	   (A) = Byte to move
;		(WPTR) = FWA of hex destination
;	Output	(WPTR) = Next address
;		 (CY) set if MBYTE caused write to disk
;	Uses	All

MBYTE	MOV	C,A
	LDA	CHKSUM
	SUB	C
	STA	CHKSUM
; Convert msb's to hex.

	MOV	A,C
	ANI	11110000B
	RAR
	RAR
	RAR
	RAR
	CALL	CONHEX
	LHLD	WPTR
	MOV	M,A		;Move a nibble
	INX	H
	CALL	TWPTR
	LHLD	WPTR
	MOV	A,C
	ANI	00001111B
	CALL	CONHEX
	MOV	M,A		;Move another nibble
	INX	H
; Subroutine to Test Write PoinTeR. Outputs file on full
; buffer.
;	Input	(HL) = New WPTR value
;	Output	(CY) set if TWPTR caused write to disk

TWPTR	SHLD	WPTR
	MOV	A,L
	CPI	WRBUFE AND 0FFH
	STC
	CMC
	RNZ			;RETURN ON NOT FULL
; Buffer is full so dump it to the destination file.

TWPTR1	PUSH	B
	PUSH	D
	PUSH	H
	LXI	D,WRBUFF
	LXI	H,4280H		;DMA ADDRESS
	CALL	MOVE
	LXI	D,DFCB
	MVI	C,21		;WRITE
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	ORA	A		;GOOD WRITE?
	JZ	CWBUFF		;YES
	LXI	D,NOWRIT
	MVI	C,9
	CALL	BDOS
	JMP	EXIT		;RETURN TO CP/M
NOWRIT	DB	0DH,0AH,'Can''t write output file.$'
; Subroutine to Clear Write BUFfer.

CWBUFF	LXI	H,WRBUFF
	SHLD	WPTR		;Restart WPTR
	PUSH	B
	MVI	B,0
	MVI	C,80H
CLOOP	MOV	M,B
	INX	H
	DCR	C
	JNZ	CLOOP
	STC			;Show that buffer is clear
	POP	B
	RET
; Subroutine to convert a 4-bit nibble to
; ASCII hex

CONHEX	ADI	90H
	DAA
	ACI	40H
	DAA
	RET
; Subroutine to READ a Sector from the source file.
; CY set if past EOF

READS	PUSH	B
	PUSH	D
	PUSH	H
	LXI	D,425CH		;FCB
	MVI	C,20		;READ
	CALL	BDOS
	ORA	A		;GOOD READ?
	STA	EOFFLG
	JZ	GOODRD
	CPI	1		;EOF?
	STA	EOFFLG		;MARK EOF
	JZ	GOODRD
	LXI	D,NOREAD
	MVI	C,9
	CALL	BDOS
	JMP	EXIT		;RETURN TO CP/M
NOREAD	DB	0DH,0AH,'Can''t read input file.$'
GOODRD	LXI	D,4280H		;DMA ADDR
	LXI	H,RDBUFF
	SHLD	RPTR
	CALL	MOVE
	POP	H
	POP	D
	POP	B
	RET

;Move 80H bytes from DE to HL

MOVE	MVI	C,80H
MOVE1	LDAX	D
	INX	D
	MOV	M,A
	INX	H
	DCR	C
	JNZ	MOVE1
	RET
; Get 16 bytes from input file
; Store them in a special buffer
; If all bytes are zero, discard them

GET16	PUSH	B
GETMOR	LXI	D,BUFF16
	MVI	B,16		;READ 16 BYTES
GETLP	LHLD	RPTR
	MOV	A,M
	STAX	D
	INX	D
	INX	H
	SHLD	RPTR
	MOV	A,L
	CPI	RDBUFE AND 0FFH
	CZ	READS		;READ A SECTOR IF NECESSARY
	DCR	B
	JNZ	GETLP
	LXI	H,BUFF16
	MVI	B,16
	XRA	A
CHKLP	ORA	M		;CHECK IF ALL 16 BYTES ARE 0
	STA	ZROFLG		;MARK GOOD BYTES
	JNZ	NOTZRO
	INX	H
	DCR	B
	JNZ	CHKLP
	LHLD	DBFWA		;ALL ZERO, GET 16 MORE
	LXI	D,16
	DAD	D
	SHLD	DBFWA
	XRA	A
	STA	ZROFLG		;MARK 16 ZEROS
	LDA	EOFFLG
	ORA	A		;READ PAST EOF?
	JNZ	NOTZRO		;LEAVE IF SO
	JMP	GETMOR
NOTZRO	POP	B
	RET
; RETURN TO CP/M WITHOUT RE-BOOTING

EXIT	LHLD	OLDSTK
	SPHL
	RET
; Buffer areas and variables.

DFCB	DB	0		;Destination filename buffer
	DB	'        HEX'
	DB	0,0,0,0,0,0,0,0
	DS	10H
RPTR	DS	2		;Read Pointer
WPTR	DS	2		;Write Pointer
CHKSUM	DS	1		;Checksum accumulator
EOFFLG	DS	1		;END OF FILE FLAG
ZROFLG	DS	1		;ZERO BYTES FLAG
OLDSTK	DS	2		;OLD STACK STORAGE
	DS	40
STACK	EQU	$
BUFF16	DS	16		;Buffer for 16 bytes
DBFWA	DS	2		;FWA of object file
RDBUFF	EQU	$		;Read sector buffer
RDBUFE	EQU	RDBUFF+80H
WRBUFF	EQU	RDBUFE		;Write sector buffer
WRBUFE	EQU	WRBUFF+80H
	END	START
