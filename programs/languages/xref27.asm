; XREF27.ASM  Cross-reference program for .ASM or .PRN files 11/09/85
;
;
; This program generates a cross-reference list for all labels in an
; .ASM, .MAC or .PRN file.  Thus it works with either an assembly level
; source code file or an assembled print file.	No other cross-reference
; program is known to have this sort of versatility and ease of use.  It
; will number the lines and generate a cross-reference listing at the
; end of the program.  If a numbered listing is not requested, it makes
; a cross-reference listing without the source code - this is often used
; to find what label names have been already used - or which labels were
; actually unnecessary as they were not used at all.  The output can be
; shown to the CRT, sent directly to the printer, or to a disk file.  If
; a disk file is used, it is given the same name as the original file,
; with an .EXR extent.
;
;-----------------------------------------------------------------------
;			current revision
;
; 11/09/85  Fixed an intermittent bug that was causing the program to
;   v27     miss seeing the EOF character and keep right on going until
;	    it bombed by filling the disk.  This occured on some longer
;	    .PRN files when adding line numbers.  Took awhile to find,
;	    as only occured occasionally.  Likely been around since the
;	    program was written.	- Irv Hoff
;
;-----------------------------------------------------------------------
;
; It is invoked by entering:
;
;	XREF FILEBNME.ASM	(output to printer)
;	XREF FILENAME.PRN CRT	(output to CRT)
;	XREF FILENAME.ASM D	(output to disk - default drive)
;	XREF FILENAME.PRN B:D	(output to disk - drive B: in this case)
;
; To get the help guide type:
;
;	XREF ? <ret>  or   XREF <ret>
;
;-----------------------------------------------------------------------
; Number of lines per output page set by equ LPAGE.  Set this equate to
; zero if you don't want any form feeds added in the cross-reference
; listing - it will still put one at the beginning and end.
;
; NREFS sets the number of label references per table entry.  This
; value should be set to the average number of references that a label
; will have in the program.  It is used to build the label reference
; table entries.  Each entry will be equal to (NREFS*2)+2.  If it is
; made unnecessarily large, then the label reference table will be very
; large with a lot of unused slots.  Example: a program with 300 labels
; will require a reference table that is at least 12600 bytes if
; NREFS=20, whereas the same program will require a reference table that
; is at least 3600 bytes if NREFS=5.  Each label that exceeds NREFS re-
; ferences will require ((Total references/NREFS) rounded up) reference
; table entries.  Recommended values: 3-5.
;
; LREFS sets the Number of labels references to be printed per output
; line.  It should be a multiple of NREFS.  If it is not, then the first
; number that is less than LREFS and is a multiple of NREFS will be
; printed on the line.	Example: if NREFS is 5 and LREFS is 13, then
; only 10 entries will be printed per line.  The total number of refer-
; ences that will fit on one line without overflow is equal to the size
; of the line minus (LABSIZ+2) divided by 6.  Example: if the line size
; is 72 characters and LABSIZ equals 10, then total number of references
; per line can be INT((72-(10+2))/6) or INT(60/6) or 10.
;
; LABSIZ sets the Label size.  This is the label size that the program
; will use in the cross reference listing.  It should be large enough to
; make each label unique in cross-reference listing.  If a label is
; larger than the value for LABSIZ, then the label will be truncated in
; the output i.e., LARGE$LABEL would be LARGE$LABE if LABSIZ was set to
; 10.  Recommended value is 8.
;
; BUFSIZ is the number of disk records that will be read when the disk
; input buffer is empty.  It is used to calculate the size of the input
; buffer and output buffers.  Input buffer size = BUFSIZ * 128.  Recom-
; mended value is from 8 to 32.  16 works well.  This represents a 2k
; buffer.  Remember there are separate buffers of this size for input
; and output, doubling the total memory used.
;
;
; NOTE: If INSECT is made too large, there will not be enough memory
; left to build the cross-reference table for a large program.	Largest
; tested values so far is 916 on a 64k system.	The file successfully
; cross-referenced was MDM740.PRN.	- JRM
;
;-----------------------------------------------------------------------
;
; DONE
; ----
;	DONE gets control when a control Z(1AH) is found
;	in the input data stream.  This routine:
;
;	1) issues a page eject
;	2) prints the cross reference table
;	3) issues a page eject
;	4) if disk output, writes out the remaining
;		sectors in the disk output buffer and
;		then closes the disk output file
;	5) closes the disk input file
;	6) displays end of program message
;
;
; SETUP OR INITIALIZATION
; -----------------------
;	1) displays program logo and version
;	2) checks for input file type PRN
;	     -if file type PRN, sets PRN switch
;	3) if operator specified FN.FT CON, then sets console
;	   output switch on.  Goes to step 5
;	4) else check for disk output option
;	     -if not disk output, default to printer output
;	     -go to step 5
;	     -else check to see if cross reference file exists
;		  -if it exists, ask operater if it is to be erased
;			-if no erase, terminate program
;			-else erase cross reference file
;	     -then create new cross reference disk file
;	     -initialize output character pointer to disk buffer
;	5) open input disk file
;	6) initialize printer buffer, address pointers for label table
;	   and reference table, set line counter to 1
;	7) return to caller
;
; DBYT
; ----
;	Put output character into disk buffer
;
;	Input = E (output character)
;
;	1) move character to buffer
;	2) if at end of buffer, go
;	   write out disk buffer
;	3) else add 1 to disk buffer
;	   pointer
;	4) subtract 1 from number of
;	   positions left in buffer
;	5) go check if operator pressed ^C
;
;
; PUTREC
; ------
;	Write out disk buffer to disk
;
;	1) initialize start of disk buffer address and number
;	   of sectors to write out
;	2) get current disk sector buffer address
;	3) add 128 to it and save for DMA of sector after
;	   current sector
;	4) do DMA for current sector buffer address
;	5) write current disk sector
;	6) if not last sector repeat steps 2 thru 5
;	7) set number of characters positions left in buffer
;	   to size of buffer
;	8) set disk output buffer pointer to front of buffer
;	9) go check to see if operator pressed control C
;
;
; GETBT
; -----
;	Routine to read a byte
;
;	Outputs: A=byte
;
;	1) is current byte pointer at
;	   end of buffer?
;	      -yes, Read disk records
;	       into buffer
;	2) move character from buffer
;	   to ACCUM
;	3) add 1 to character pointer
;	   and save pointer
;	4) return to caller
;
;
; GETREC
; ------
; Read the number of input records specified by BUFSIZ.  The buffer
; starts at TBUF.  Before each DMA, the buffer address is incremented by
; 128 and saved in IDADDR.  This address will be used for the DMA after
; the current sector is read.  The logic is:
;
;	1) get current buffer address
;	2) add 128 to it and save it
;	3) issue DMA for current buffer address
;	4) read the disk record,
;	      -if end of file goto step 7
;	5) decrement number of sectors to read
;	6) if not number of sectors not zero
;	      -repeat above
;	7) reset character pointer to first buffer
;	8) return to caller
;
;-----------------------------------------------------------------------
;			  prior updates
; 09/09/85  Rewrote the display routine so it has all reference numbers
;   v26     lined up uniformly, with a leading asterisk on the number
;	    representing the line where the label is defined.  Other
;	    changes.			- Irv Hoff
;
; 01/13/85  Modified help message and introduced XRF-only option, most
;   v25     editors can easily find a line with a number.  Added markers
;	    " >>" for label-definition.  Shortened line number display
;	    to be consistent with CREF output.	Moved code to conserve
;	    space.  Moved comments from M80 source which are no longer
;	    needed as LASM is there and does the job.
;					- B. Eiben
;
; 01/30/83  Added operation (and pseudo) codes for the Z80 and M80 as-
;   v24     semblers.  While M80 CREF80 are superior they are limited by
;	    the size of the CRF files since instead of TAB space fill is
;	    used (an 80K MAC file expands to a 240K CRF file).	This
;	    program will handle at least 1200  labels in 48K RAM.  Even
;	    without flagging the defining statement, this program is
;	    quite useful.		- RMG
;
; 03/15/82  This program would lock up if there was a comment line that
;   v23     started with an asterisk '*' instead of a semicolon.  The
;	    program then processed the whole line as a valid line of as-
;	    sembly-level code.	This usually resulted in the cross re-
;	    ference program locking up if there were a lot of lines that
;	    started with an asterisk.  The program now treats an aster-
;	    isk the same as a semicolon.  This was done by changing the
;	    table CTAB1 so that the program branches to LSEMI when it
;	    finds an asterisk.	Also fixed bug that occurred when the
;	    last record of a file was completely filled with data and
;	    thus had no control Z's (EOF characters) in it.  This was
;	    done by always placing two control Z's after the last record
;	    was read.  Finally fixed a bug that showed up only when a
;	    program had no symbols or labels in it.  Added a check for
;	    an empty label table before attempting to print the label
;	    symbol table.		- JRM
;
; 03/06/82  Changed the code so the size of output disk buffer can be
;   v22     specified at assembly time.  The size is set by OUTSECT
;	    which equals the number of disk sectors to be written when
;	    the buffer is full.  Implemented the same feature for disk
;	    input.  INSECT sets the number of disk records to be read
;	    into the input buffer.  On file type PRN the was a bug.
;	    Whenever the first label on a line was preceded by a char-
;	    acter, the line was not listed in the cross-reference list-
;	    ing.  This was caused by skipping over the first 16 char-
;	    acters in the line on a CR (carriage return) instead of on a
;	    LF (line feed).  This bug has been fixed.  Added help func-
;	    tion.  This is invoked by entering XFER ?
;					- JRM
;
; 03/03/82  Added a 2k buffer for disk output writes.  This was done to
;   v21     speed up the execution of program when disk output was spec-
;	    ified.  Fixed bug when page size was specified.  CP/M assem-
;	    bler was not doing the conditional IF assembly correctly.
;	    Changed the code to test if page size is in effect by test-
;	    ing LPAGE to see if it is zero.  Changed test to question to
;	    erase existing disk cross-reference file to handle lower-
;	    case as well as upper-case.
;					- JRM
;
; 02/20/82  Changed code so that the size of the label that is refer-
;   v20     enced in the cross-reference listing can be set at assembly
;	    time.  The original program only allowed for 5 characters
;	    per label.	This did not allow for separate unique labels
;	    where the uniqueness occurred after the first 5 characters.
;	    I tested this function for a length of 5, 8, and 10 chara-
;	    cters  labels.  It should work for any length of label.  I
;	    also allowed the '$' character to be a valid character in a
;	    label.  The equ LABSIZ was added and all other values and
;	    variables that are dependent on the size of the label are
;	    expressed using LABSIZ.
;
;		Example: LSIZ EQU LABSIZ+3
;
;	    Added a disk file output option.  The output disk file will
;	    use the filename of the input file and always have a file
;	    type of 'XRF'.  This option is enabled by specifying a 'D'
;	    as the second parameter when executing the program.  The
;	    user can optionally specify a different drive from the de-
;	    fault drive for the cross-reference disk output.
;
;		Example: XREF FILENAME.ASM D
;			 XREF FILENAME.PRN B:D
;						- JRM
;
;-----------------------------------------------------------------------
;
;
; Equates that can be changed
;
BUFSIZ	EQU	16		; In and out buffer size, 8 records = 1k
LABSIZ	EQU	10		; Number of characters per label
LPAGE	EQU	0		; Num lines per page if peject is true
LREFS	EQU	10		; References per output line
NREFS	EQU	5		; Number of references per ref tbl entry
;
;
; Equates that can't be changed
;
LSIZ	EQU	LABSIZ+3	; Label table entry size
REFSZ	EQU	2+(NREFS*2)	; Number of bytes in ref block
RSIZ	EQU	05		; Size of rtab table entry
;
BS	EQU	08H		; Backspace
CR	EQU	0DH		; Carriage return
EOF	EQU	1AH		; EOF code
LF	EQU	0AH		; Line feed
;
;
; Operating system equates
;
BOOT	EQU	4200H		; Reboot entry point
BDOS	EQU	4205H		; CP/M entry point
;
MEMSZ	EQU	4206H		; End of memory pointer
TFCB	EQU	425CH		; Trans. FCB
;
CONIN	EQU	01		; Console input function code
PSTRING	EQU	09		; Print string function code
OPEN	EQU	15		; Open function code
CLOSE	EQU	16		; Close file function code
DELETE	EQU	19		; Delete file function code
READ	EQU	20		; Read disk function code
WRITE	EQU	21		; Write disk function code
MAKE	EQU	22		; Make file function code
SETDMA	EQU	26		; Set DMA function code
;
;
; Main loop
;
;
	ORG	4300H
;
;
START:	LXI	SP,STACK	; Set stack pointer
	CALL	SETUP		; Initialize
;
MAIN:	CALL	GETBT		; Get a byte from source file
;
MAIN1:	CALL	CKNUM		; Test for numeric
	JNC	LNUM		; Yes, found a number, process
	CALL	CKALP		; Test for alphabetic
	JNC	LALPH		; Yes, process
	LXI	H,CTAB1		; Point to character table
	CALL	LOOK		; Look up character in character table
	JC	MAIN		; Not found, ignore
	PCHL			; Execute routine
;.....
;
;
; Finished
;
; Final label table print
;
DONE:	MVI	E,0CH		; Printer form feed character
	CALL	PBYT
	MVI	A,0FFH		;
	STA	LISTFLG		; CREF-list on always
	LHLD	LABBT		; Get label table bottom
	MVI	A,0FFH		; Check to see if there were...
	CMP	M		; Any labels in the program
	JZ	DLP4		; No, don't print label table
	SHLD	LAB		; Set label pointer
	LHLD	LABTP		; Get label table top
	MVI	M,0FFH		; End off label table
;
DLP1:	LHLD	LAB		; Get label table pointer
	CALL	PLAB		; Print label
	LHLD	LAB
	LXI	D,LABSIZ+1	; Offset to reference link
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M		; Get reference block address
	XCHG			; Into HL
	SHLD	REF
	CALL	PREF		; Print references
	LHLD	LAB		; Get label table pointer
	LXI	D,LSIZ		; Size of symbol table entry
	DAD	D
	SHLD	LAB
	MOV	A,M		; Get byte
	CPI	0FFH		; End of table?
	JNZ	DLP1		; Loop
;
DLP2:	MVI	E,0CH		; Printer form feed character
	CALL	PBYT
	LDA	DISKOUT		; Get disk output switch
	ORA	A		; Disk output being used?
	JZ	DLP3		; No, issue end msg & return to CP/M
	LXI	H,DISKBUF	; Get output disk buffer
	LXI	D,OFCB		; And out fcb
	CALL	DCLOSE		; And close output disk file
;
DLP3:	LXI	D,TFCB		; Close input file
	MVI	C,CLOSE
	CALL	BDOS
	LXI	D,DONEMSG	; Tell operator we're done
	CALL	PSOUT
	JMP	BOOT		; And return to CP/M
;.....
;
;
DLP4:	LXI	H,NOLABS	; Get no label message
	MVI	B,28		; Number of characters in message
;
DLP5:	MOV	E,M		; Print the message
	CALL	PBYT
	INX	H
	DCR	B
	JNZ	DLP5
	JMP	DLP2		; Go close files
;
;
; Label print routine
;
PLAB:	MVI	B,LABSIZ	; Label size
;
PLAB1:	MOV	E,M		; Get byte
	CALL	PBYT		; Print byte
	INX	H
	DCR	B
	JNZ	PLAB1
	MVI	E,' '
	CALL	PBYT		; Print 2 spaces
	CALL	PBYT
	RET
;.....
;
;
; Reference print routine
;
PREF:	MVI	A,LREFS/NREFS	; Number of blocks to print on one line
	STA	NLINS		; To nlins
;
PREF1:	LHLD	REF		; Get reference block address
	INX	H
	INX	H		; Bump to first reference number
	SHLD	TEMP		; Save reference number address
	MVI	A,(REFSZ-2)/2	; Number of ref slots
	STA	LABCT		; Save in symct
;
PREF2:	LHLD	TEMP		; Get reference slot address
	MOV	E,M
	INX	H
	MOV	D,M		; Get reference
	LXI	H,0000		; Zero?
	CALL	CPHL
	JZ	CRLF		; Yes, done
	PUSH	D
	MVI	E,' '
	CALL	PBYT
	POP	D
	MOV	A,D
	ANI	080H		; High bit set ?
	JZ	PREF3		; Nope
;
	MOV	A,D		; If a label entry, show
	ANI	07FH
	MOV	D,A		; Clear it
	PUSH	D
	MVI	E,'*'
	CALL	PBYT
	POP	D
	JMP	PREF4		; Skip next space
;
PREF3:	PUSH	D
	MVI	E,' '
	CALL	PBYT
	POP	D
;
PREF4:	XCHG			; Get number in HL
	CALL	DECOT		; Convert
	CALL	DECPNT		; Print it
	LHLD	TEMP		; Get reference slot address
	INX	H
	INX	H		; Bump to next slot
	SHLD	TEMP
	LDA	LABCT		; Get count
	DCR	A		; Decrement
	STA	LABCT
	JNZ	PREF2
	LHLD	REF		; Get ref block address
	MOV	E,M
	INX	H
	MOV	D,M		; Get link to next block
	LXI	H,0000
	CALL	CPHL		; Any more blocks?
	JZ	CRLF		; No, exit
;
	XCHG			; Yes, set next block pointer in ref
	SHLD	REF
	LDA	NLINS
	DCR	A		; Decrement lines count
	STA	NLINS
	JNZ	PREF1		; And print more on same line
	CALL	CRLF		; Print CR and LF
	MVI	B,LABSIZ+2	; Indent continuation line...
;
PREF5:	MVI	E,' '		; With spaces
	CALL	PBYT		; Print spaces
	DCR	B
	JNZ	PREF5		; Print 6 spaces
	JMP	PREF
;.....
;
;
; Character parsing routines
;
LALPH:	LXI	H,SBUF		; Point to label buffer
	MVI	C,LABSIZ
	MVI	A,' '		; Fill label...
;
LALX:	MOV	M,A		; With...
	INX	H		; Blanks
	DCR	C
	JNZ	LALX		; Clear label buffer
	LXI	H,SBUF
	SHLD	LABPT
	MVI	A,00
	STA	LABCT		; Reset label pointer+count
	LDA	CHAR		; Get character again
	CALL	GTLAB		; Collect identifier
;
LALC:	CALL	GETBT		; Get a byte from source file
	CALL	CKNUM		; Test for number
	JNC	LAL3		; Yes, continue
	CALL	CKALP		; Test for alphabetic
	JNC	LAL3		; Yes, continue
	CALL	CRES		; Test for reserved word
	JC	LAL1		; No, continue
;
LAL0:	CALL	LINUP		; Up LINLAB
	LDA	CHAR		; Get character that ended ID
	JMP	MAIN1		; Continue scan
;.....
;
;
;
LAL1:	CALL	FIND		; See if defined
	JC	LAL2		; No, continue
	CALL	ADDRF		; Yes, add reference
	JMP	LAL0		; Done
;.....
;
;
LAL2:	CALL	ENLAB		; Enter label definition
	CALL	ADDRF		; Add reference
	JMP	LAL0		; Continue
;.....
;
;
LAL3:	CALL	GTLAB		; Collect identifier
	JMP	LALC		; Continue
;.....
;
;
LNUM:	CALL	GETBT		; Get byte
	CALL	CKNUM		; Test for numeric
	JNC	LNUM		; Yes, continue
	CALL	CKALP		; Test for alphabetic
	JNC	LNUM		; Yes, continue
	JMP	MAIN1		; Continue with main scan
;.....
;
;
LQUOT:	CALL	GETBT		; Get a byte
	CPI	''''		; See if string quote
	JNZ	LQUOT		; No, keep looping
	CALL	GETBT		; Get next byte
	CPI	''''		; Test for doubles
	JZ	LQUOT		; Yes, start scan again
	JMP	MAIN1		; No, continue in main scan
;.....
;
;
LSEMI:	CALL	GETBT		; Get a byte
	CPI	CR		; Wait for cr
	JNZ	LSEMI		; Continue
	JMP	MAIN1		; Enter main loop
;.....
;
;
LCR:	CALL	PLINE		; Print line
	LHLD	LCNT		; Get line number
	INX	H		; Bump line number
	SHLD	LCNT		; Store
	JMP	MAIN
;.....
;
;
LLF:	PUSH	PSW		; Save char
	LDA	FTPRN		; Is it file...
	ORA	A		; Type prn?
	JZ	LLF2		; Yes, skip 1rst 16 char
	POP	PSW		; Restore char
;
LLF1A:	PUSH	PSW		;
	MVI	A,0		; Reset LINLAB
	STA	LINLAB
	POP	PSW
	JMP	MAIN
;.....
;
;
LLF2:	POP	PSW		; Restore character
	MVI	B,16		; # of char to skip over
;
LLF3:	CALL	GETBT		; Get next byte
	CPI	CR		; Carriage return?
	JZ	LCR		; Yes, get next line
	CPI	EOF		; End of file now?
	JZ	DONE		; If yes, finish up
	DCR	B		; Skipped all char?
	JNZ	LLF3		; No, continue skipping
	JMP	LLF1A		; Continue
;.....
;
;
LIGN:	JMP	MAIN		; Re-enter main loop
LSPC	EQU	LIGN
LTAB	EQU	LIGN
LDOL	EQU	LIGN
LDEL	EQU	LIGN
;
;
;----------------------------------------------------------------------
;			   subroutines
;
; Check for reserved word
;
CRES:	LXI	H,RTAB		; Point to reserved word table
	SHLD	TEMP		; Save in temp word
;
CRES1:	LHLD	TEMP		; Get table pointer
	LXI	D,SBUF		; Point to label
	MVI	B,5		; Label size
;
CRES2:	LDAX	D		; Get label byte
	CMP	M		; Compare against table entry
	RC			; Less, not in table
	JNZ	CRES3		; Greater, get next table entry
	INX	D		; Bump pointers
	INX	H
	DCR	B		; Decrement byte count
	JNZ	CRES2		; Keep testing
	JMP	CRES4		; Found
;
CRES3:	LHLD	TEMP		; Get table pointer
	LXI	D,RSIZ		; Size of entry
	DAD	D		; Bump pointer
	SHLD	TEMP		; Store new pointer
	MOV	A,M		; Get table byte
	CPI	0FFH		; End of table?
	JNZ	CRES1		; No, loop
	STC			; Set carry (not in table)
	RET
;.....
;
;
CRES4:	ORA	A		; Reset carry
	RET
;.....
;
;
; Find label in table
;
FIND:	LHLD	LABBT		; Get begin of sym table
	SHLD	LAB		; Set temp pointer
;
FIND1:	LHLD	LAB		; Get temp pointer
	LXI	D,SBUF		; Point to current label
	MVI	B,LABSIZ	; Label size
;
FIND2:	LDAX	D		; Get byte from sbuf
	CMP	M		; Compare to sym table byte
	RC			; Greater, not in table
	JNZ	FIND3		; Less, get next table entry
	INX	D		; Bump pointer
	INX	H		; Bump pointer
	DCR	B		; Decrement byte count
	JNZ	FIND2		; Loop
	RET			; True zero, found
;...
;
;
FIND3:	LHLD	LAB		; Get current pointer
	LXI	D,LSIZ		; Label table entry size
	DAD	D		; Bump pointer
	XCHG			; Into de
	LHLD	LABTP		; Get top of label table
	CALL	CPHL		; Test for end of table
	JZ	FIND4		; Yes, done
	JC	FERR		; Table overflow, error
	XCHG			; Current pointer into HL
	SHLD	LAB		; Set current pointer
	JMP	FIND1		; Loop
;
FIND4:	STC			; Set carry for not found
	LHLD	LABTP		; Get current top
	SHLD	LAB		; Set current pointer
	RET
;.....
;
;
FERR:	LXI	D,EMSG1		; Label table error message
;
FERR1:	CALL	PSOUT		;
	JMP	BOOT		; Exit
;
FERR2:	LXI	D,EMSG6		; No room for label table
	JMP	FERR1
;
;
; Add reference to ref table
;
ADDRF:	LHLD	LAB		; Get label pointer
	LXI	D,LABSIZ+1	; Offset past label&flags
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M		; Get reference pointer
	LXI	H,0000
	CALL	CPHL		; Test for zero ref ptr
	JZ	BLDRF		; Yes, build reference entry
;
LINK1:	XCHG			; Ref ptr in hl
	MOV	E,M		; Get ref link
	INX	H
	MOV	D,M		; Into de
	DCX	H		; Reposition hl
	PUSH	H		; Save ref ptr
	LXI	H,0000
	CALL	CPHL		; If link is zero
	POP	H
	JNZ	LINK1		; Non zero, get next link
	SHLD	REF		; Save ref pointer
	INX	H
	INX	H		; Skip to first ref number
	MVI	B,(REFSZ-2)/2	; Number of ref numbers/entry
;
LINK3:	MOV	E,M		; Get ref number
	INX	H
	MOV	D,M
	DCX	H		; Reposition
	PUSH	H		; Save ref num addr
	LXI	H,0000
	CALL	CPHL		; See if ref num is zero
	POP	H
	JZ	ENREF		; Yes, enter reference
	INX	H
	INX	H		; Skip to next ref num
	DCR	B		; Decrement count
	JNZ	LINK3		; Try again at next slot
	CALL	ADBLK		; Add new ref block
	LHLD	REF		; Get ref pointer
	INX	H
	INX	H		; Skip to first ref slot
;
ENREF:	PUSH	H		; Save ref slot addr
	LHLD	LCNT		; Get line number
	XCHG			; Into de
	POP	H		; Get ref slot addr
	LDA	LINLAB		; First label on line ?
	ORA	A
	JNZ	ENREF1		; Nope
	CALL	LINUP		; Up LINLAB
	MOV	A,D
	ADI	080H
	MOV	D,A		; Set high bit
;
ENREF1:	MOV	M,E
	INX	H
	MOV	M,D		; Store line ref
	RET			; Done
;.....
;
;
; Build reference table block
;
BLDRF:	LHLD	LAB		; Get label pointer
	LXI	D,LABSIZ+1	; Offset to ref pointer
	DAD	D
	SHLD	REF		; Set temp ref pointer to here
	CALL	ADBLK		; Add block
	LHLD	REF		; Get real ref pointer
	INX	H
	INX	H		; Position to first ref slot
	JMP	ENREF		; Add reference
;
ADBLK:	LHLD	REFBT		; Get ref bottom
	LXI	D,REFSZ		; Subtract ref size
	MOV	A,L
	SUB	E
	MOV	L,A
	MOV	A,H
	SBB	D
	MOV	H,A
	SHLD	TEMP		; Save new ref bottom
	XCHG			; Into de also
	LHLD	LABTP		; Get label top
	CALL	CPHL		; Check for bump
	JZ	FERR2		; Yes, no room
	JNC	FERR2		; No room
	LHLD	TEMP		; Get ref bottom
	XCHG			; Into DE
	LHLD	REF		; Get ref pointer
	MOV	M,E		; Set link
	INX	H
	MOV	M,D		; To new reference check
	LHLD	TEMP		; Get new reference block address
	SHLD	REF		; Store in reference
	MVI	B,REFSZ		; Size of ref block
	MVI	A,0
;
ADB2:	MOV	M,A		; Zero the ref block
	INX	H
	DCR	B
	JNZ	ADB2
	LHLD	TEMP		; Get new ref bottom
	SHLD	REFBT		; Set refbt
	RET
;.....
;
;
; Enter label in label table
;
ENLAB:	LHLD	LAB		; Get label pointer
	XCHG			; Into DE
	LHLD	LABTP		; Get label table top
	CALL	CPHL		; Check for end of table
	JZ	NWLAB		; Yes, add label at end
	LXI	D,LSIZ		; Label table entry size
	DAD	D		; Calculate new end of table
	XCHG			; Into de
	LHLD	REFBT		; Reference table bottom
	CALL	CPHL		; Test for table overflow
	LXI	D,EMSG7		; Address of error msg in of overflow
	JZ	FERR1		; Full, error
	JC	FERR1		; Yes, error
	LHLD	LABTP		; Get table top
	LXI	D,LSIZ-1	; Bump to end of entry
	DAD	D
	SHLD	TO		; Store in to address
	LXI	D,LSIZ
	MOV	A,L
	SUB	E
	MOV	L,A
	MOV	A,H
	SBB	D
	MOV	H,A		; Subtract size of one entry
	SHLD	FROM		; Store as from address
	LHLD	LAB		; Get current pointer
	SHLD	LIMIT		; Store as limit address
	CALL	MVUP		; Move table up in memory
;
NWLAB:	LHLD	LAB		; Get current pointer
	LXI	D,SBUF		; Point to label
	MVI	B,LABSIZ	; Size of label
	CALL	MOVE		; Copy label to table
	MVI	A,0
	MOV	M,A
	INX	H
	MOV	M,A
	INX	H
	MOV	M,A		; Set pointers to 0000
	LHLD	LABTP		; Get label table top
	LXI	D,LSIZ		; Get label entry size
	DAD	D		; Bump
	SHLD	LABTP		; Store new top
	RET
;.....
;
;
; Move label table up
;
MVUP:	LHLD	TO		; Get to pointer
	MOV	B,H
	MOV	C,L		; Into BC
	LHLD	FROM		; Get from pointer
	XCHG			; Into DE
	LHLD	LIMIT		; Get limit address
;
MVUP2:	LDAX	D		; Get from byte
	STAX	B		; Store at to address
	CALL	CPHL		; Compare from to limit
	RZ			; Exit if done
	DCX	B		; Decrement to
	DCX	D		; Decrment from
	JMP	MVUP2		; Loop
;.....
;
;
; General purpose move routine
;
MOVE:	LDAX	D		; Get byte
	MOV	M,A		; Store byte
	INX	D
	INX	H		; Bump pointers
	DCR	B		; Decrement count
	JNZ	MOVE		; Loop
	RET
;.....
;
;
; Binary to decimal conversion
;
DECOT:	LXI	D,DEC
	XCHG
	LXI	B,10000
	CALL	DIG
	LXI	B,1000
	CALL	DIG
	LXI	B,100
	CALL	DIG
	LXI	B,10
	CALL	DIG
	LXI	B,1
	CALL	DIG
	RET
;.....
;
;
DIG:	MVI	M,'0'
;
DI0:	MOV	A,E
	SUB	C
	MOV	E,A
	MOV	A,D
	SBB	B
	MOV	D,A
	JM	DI2
	INR	M
	JMP	DI0
;
DI2:	MOV	A,E
	ADD	C
	MOV	E,A
	MOV	A,D
	ADC	B
	MOV	D,A
	INX	H
	RET
;.....
;
;
; Print number string in DEC
;
DECPNT:	LXI	H,DEC+1		; Point to dec string
;
DCPNT1:	MOV	E,M		; Get string byte
	MOV	A,E
	CPI	'$'		; Done?
	RZ			; Yes
;
	CALL	PBYT		; Print byte
	INX	H		; Bump pointer
	JMP	DCPNT1
;.....
;
;
; Up LINLAB after label found
;
LINUP:	PUSH	PSW
	LDA	LINLAB
	INR	A
	STA	LINLAB		; Found first separator
	POP	PSW
	RET
;.....
;
;
; Test for alphabetic character
;
CKALP:	CPI	'$'		; Treat '$' like a char
	RZ
	CPI	'A'		; Ascii 'a'
	RC			; No, exit
	CPI	'Z'+1
	CMC
	RET
;.....
;
; Test for numeric character
;
CKNUM:	CPI	'0'
	RC
	CPI	'9'+1
	CMC
	RET
;.....
;
;
; Look up character in parse table
;
LOOK:	LXI	D,0003		; Table entry size
	MOV	B,A		; Argument byte in b
;
LOOK2:	MOV	A,M		; Get table byte
	CPI	0FFH		; End of table?
	JZ	LOOKN		; Yes, not found
	CMP	B		; Compare
	JZ	LOOKY		; Found
	DAD	D		; Bump pointer
	JMP	LOOK2		; Loop
;
LOOKN:	STC			; Carry = not found
	RET
;.....
;
;
LOOKY:	INX	H		; Skip to table byte
	MOV	E,M
	INX	H
	MOV	D,M		; Table entry in de
	XCHG			; Into hl
	RET
;.....
;
;
; Print source line with number
;
PLINE:	LHLD	LCNT		; Get line number
	CALL	DECOT		; Convert to decimal
	CALL	DECPNT		; Print it
;
PL1:	MVI	E,' '
	CALL	PBYT
	LDA	FTPRN
	ORA	A
	JZ	PL11
	MVI	E,' '
	CALL	PBYT
;
PL11:	LXI	H,PBUF		; Point to print buffer
	XRA	A
	STA	COL		; Set column count
;
PL41:	MOV	E,M		; Get byte
	MOV	A,E
	CPI	CR		; Done?
	JZ	PL5
	CPI	LF		; Lf?
	JZ	PL4A		; Yes, ignore
	CPI	09H		; Tab?
	JNZ	PL42		; No, continue
	PUSH	H		; Save hl
;
PL43:	MVI	E,' '
	CALL	PBYT		; Print space
	LXI	H,COL
	INR	M
	MOV	A,M
	ANI	07H		; Modulo 8
	JNZ	PL43
	POP	H
	JMP	PL4A
;
PL42:	LDA	COL
	INR	A
	STA	COL
	CALL	PBYT		; Print byte
;
PL4A:	INX	H
	JMP	PL41
;
PL5:	CALL	CRLF		; Print cr,lf
	LXI	H,PBUF
	SHLD	LPNT		; Reset line pointer
	RET
;.....
;
;
; Collect label in label buffer
;
GTLAB:	MOV	B,A		; Save char
	LDA	LABCT		; Get label count
	CPI	LABSIZ		; Max?
	RNC			; Yes, done
	INR	A
	STA	LABCT
	LHLD	LABPT
	MOV	M,B
	INX	H		; Bump label pointer
	SHLD	LABPT
	RET
;.....
;
;
; Printer interfaces
;
; Print a single byte
;
PBYT:	PUSH	B
	PUSH	D
	PUSH	H
	PUSH	PSW
;
	LDA	LISTFLG		; Listing on ?
	ORA	A
	JZ	PBYT3		; No listing
	LDA	DISKOUT		; Disk output...
	ORA	A		; In effect?
	JNZ	DBYT		; Yes, go write to disk
	MVI	C,05
	LDA	CONSOLE		; Get console out switch
	ORA	A		; Console output?
	JZ	PBYT2		; No, print output
	MVI	C,2		; Console output
;
PBYT2:	CALL	BDOS
;
PBYT3:	MVI	C,11		; Check console status
	CALL	BDOS
	ORA	A		; If zero, ok
	JZ	PBYTX		; Exit
	MVI	C,1
	CALL	BDOS		; Read console char
	CPI	3
	JZ	BOOT		; Abort if ^C, otherwise ignore
;
PBYTX:	POP	PSW
	POP	H
	POP	D
	POP	B
	RET
;.....
;
;
; Put output character into disk buffer - input=e (output character)
;
DBYT:	MOV	A,E		; Save char to be put in buffer
	LHLD	DSKCNT		; Get num of char left in buf
	XCHG			; Put num in d,e
	LHLD	DCHAR		; Point to next char in buf
	MOV	M,A		; Put char in disk buf
	DCR	E		; At end of buf?
	JNZ	DBYT1		; No, don't write buffer
	DCR	D		; At end of buf?
	JZ	PUTREC		; Yes, go write buffer
;
DBYT1:	INX	H		; Point to next char in buf
	SHLD	DCHAR		; Save next pos
	XCHG			; Put num of char left in h,l
	SHLD	DSKCNT		; Save num of remaining char
	JMP	PBYT3		; Go check console status
;.....
;
;
; Write out disk buffer to disk
;
PUTREC:	LXI	H,DISKBUF	; Address of disk buffer
	SHLD	BUFADR		; Save it for later dma's
	MVI	B,BUFSIZ	; Number of disk sectors to write
;
PUTRC2:	PUSH	B		; Save sector count
	LHLD	BUFADR		; Get disk buffer address
	XCHG			; Put it in d,e for dma
	LXI	H,80H		; Put 128 h,l
	DAD	D		; Add 128 to disk buf adr for next dma
	SHLD	BUFADR		; Save it for next dma
	MVI	C,SETDMA	; Point dma to...
	CALL	BDOS		; Correct buffer
	LXI	D,OFCB		; Get output disk fcb
	MVI	C,WRITE		; Write sector...
	CALL	BDOS		; To disk
	ORA	A		; Was write successfull?
	POP	B		; Restore num of sectors left
	LXI	D,EMSG4		; Get err msg in case write failed
	JNZ	FERR1		; Disk write failed, display err msg, quit
	DCR	B		; Written 16 sectors yet?
	JNZ	PUTRC2		; No, continue writing disk sectors
	LXI	H,BUFSIZ*128	; Put disk buffer size into HL
	SHLD	DSKCNT		; Set num of char left in buf to buffer size
	LXI	H,DISKBUF	; Point to front...
	SHLD	DCHAR		; Of disk buffer
	JMP	PBYT3		; Go check console status for ^C
;.....
;
;
; Issue CR, LF and test page
;
CRLF:	MVI	E,CR
	CALL	PBYT
	MVI	E,LF
	CALL	PBYT
	LDA	LINES
	INR	A
	STA	LINES		; Increment line count
	MVI	A,LPAGE		; Get number of lines
	ORA	A		; Is it zero?
	LDA	LINES
	RZ			; Yes, return
	CPI	LPAGE		; Test line count
	RNZ
	MVI	E,0CH		; Printer form feed character
	CALL	PBYT
;.....
;
;
; Character parsing table
;
CTAB1:	DB	CR
	DW	LCR
	DB	LF
	DW	LLF
	DB	''''
	DW	LQUOT
	DB	';'
	DW	LSEMI
	DB	' '
	DW	LSPC
	DB	09H
	DW	LTAB
	DB	'$'
	DW	LDOL
	DB	'('
	DW	LDEL
	DB	')'
	DW	LDEL
	DB	'+'
	DW	LDEL
	DB	'-'
	DW	LDEL
	DB	'*'
	DW	LSEMI
	DB	'/'
	DW	LDEL
	DB	','
	DW	LDEL
	DB	':'
	DW	LDEL
	DB	EOF
	DW	DONE
	DB	0FFH
	DW	0000H
;.....
;
;
; Reserved word table
;
RTAB:	DB	'$    ','8080 '
	DB	'A    ','ACI  ','ADC  ','ADD  ','ADI  '
	DB	'AF   ','ANA  ','AND  ','ANI  ','ASEG '
	DB	'B    ','BC   ','BIT  '
	DB	'C    ','CALL ','CC   ','CCF  ','CM   '
	DB	'CMA  ','CMC  ','CMP  ','CNC  ','CNZ  '
	DB	'COMME','COMMO','COND ','CP   ','CPD  '
	DB	'CPDR ','CPE  ','CPI  ','CPL  ','CPO  '
	DB	'CSEG ','CZ   '
	DB	'D    ','DAA  ','DAD  ','DB   ','DC   '
	DB	'DCR  ','DCX  ','DE   ','DEC  ','DEFB '
	DB	'DEFL ','DEFM ','DEFW ','DI   ','DJNZ '
	DB	'DS   ','DSEG ','DW   '
	DB	'E    ','EI   ','ELSE ','END  ','ENDC '
	DB	'ENDIF','ENDM ','ENTRY','EQ   ','EQU  '
	DB	'EX   ','EXX  ','EXITM','EXT  ','EXTRN'
	DB	'GE   ','GLOBA','GT   '
	DB	'H    ','HL   ','HIGH ','HALT '
	DB	'IF   ','IFB  ','IFDEF','IFE  ','IFF  '
	DB	'IFNB ','IFNDE','IFT  ','IF1  ','IF2  '
	DB	'IM   ','IN   ','INC  ','INCLU','IND  '
	DB	'INDR ','INIR ','INR  ','INX  ','IRP  '
	DB	'IRPC ','IX   ','IY   '
	DB	'JC   ','JM   ','JMP  ','JNC  ','JNZ  '
	DB	'JP   ','JPE  ','JPO  ','JR   ','JZ   '
	DB	'L    ','LALL ','LD   ','LDA  ','LDAX '
	DB	'LDD  ','LDDR ','LDI  ','LDIR ','LE   '
	DB	'LHLD ','LIST ','LOCAL','LOW  ','LT   '
	DB	'LXI  '
	DB	'M    ','MACRO','MOD  ','MOV  ','MVI  '
	DB	'NAME ','NC   ','NE   ','NEG  ','NOP  '
	DB	'NOT  ','NUL  ','NZ   '
	DB	'OR   ','ORA  ','ORG  ','ORI  ','OTDR '
	DB	'OTIR ','OUT  ','OUTI ','OUTD '
	DB	'P    ','PAGE ','PCHL ','PE   ','PO   '
	DB	'POP  ','PRINT','PSW  ','PUBLI','PUSH '
	DB	'RADIX','RAL  ','RAR  ','RC   ','REPT '
	DB	'RES  ','RET  ','RETI ','RL   ','RLA  '
	DB	'RLC  ','RLCA ','RLD  ','RM   ','RNC  '
	DB	'RNZ  ','RP   ','RPE  ','RPO  ','RR   '
	DB	'RRA  ','RRC  ','RRCA ','RRD  ','RST  '
	DB	'RZ   '
	DB	'SALL ','SBB  ','SBC  ','SBI  ','SCF  '
	DB	'SET  ','SHL  ','SHLD ','SHR  ','SLA  '
	DB	'SP   ','SPHL ','SRA  ','SRL  ','STA  '
	DB	'STAX ','STC  ','SUB  ','SUBTT','SUI  '
	DB	'TITLE'
	DB	'XALL ','XCHG ','XLIST','XOR  ','XRA  '
	DB	'XRI  ','XTHL '
	DB	'Z    ','Z80  '
	DB	0FFH		; End of reserved word table
;.....
;
;
; Routine to open a disk file
; input: DE=A(FCB)
;
FOPEN:	MVI	C,OPEN		; Open code
	CALL	BDOS		; Issue open
	CPI	0FFH		; Error?
	RNZ			; No error
	LXI	D,EMSG0
	JMP	FERR1
;.....
;
;
; Routine to close output disk cross-reference file
; input: DE=ADDR(FCB)
;	 HL=ADDR(BUFFER)
;
DCLOSE:	PUSH	D		; Save fcb address
	PUSH	H		; Save buffer address
	LHLD	DSKCNT		; Put number of char left...
	XCHG			; In buffer into d,e
	LHLD	DCHAR		; Point to next char in output buf
	MVI	A,1AH		; Put a control z in accum
;
DCLSE2:	MOV	M,A		; Fill...
	INX	H		; Rest of...
	DCR	E		; Buffer...
	JNZ	DCLSE2		; With...
	DCR	D		; Control z's.
	JNZ	DCLSE2
	POP	H		; Point to...
;
DCLSE4:	XCHG			; Output buffer
	LXI	H,128		; Put 128 into h,l
	DAD	D		; Add 128 to disk buf addr for next dma
	SHLD	BUFADR		; Save it for next dma after this one
	MVI	C,SETDMA	; Disk buffer for...
	CALL	BDOS		; Last disk write
	POP	D		; Do last...
	PUSH	D		; (d,e contains ofcb)...
	MVI	C,WRITE		; Disk...
	CALL	BDOS		; Write
;
;
; Check to see if last record has been written.  Do this by comparing
; the address of the next available character to the address of the buf-
; fer for the next disk write.	If the address of the next available
; character is equal to or greater, close the file.
;
	LHLD	DCHAR		; Put high order address
	XCHG			; Of last char+1...
	MOV	A,D		; Into accum
	LHLD	BUFADR		; Get addr of next disk buffer
	CMP	H		; Compare to last char+1 in buffer
	JC	DCLSE5		; If next addr is greater, close file
	JNZ	DCLSE4		; If not equal, continue
	MOV	A,E		; Put low order address of last char+1
	CMP	L		; Into accum and test
	JNC	DCLSE4		; If not less, do another write
;
DCLSE5:	POP	D		; Close the...(d,e contains ofcb)
	MVI	C,CLOSE		; Output disk
	CALL	BDOS		; Cross ref file
	CPI	0FFH		; Close successfull?
	RNZ			; Yes, return
	LXI	D,EMSG5		; No, display error msg...
	JMP	FERR1		; And quit
;.....
;
;
; Rroutine to read a byte
; outputs: A=BYTE
;
GETBT:	LXI	H,TBUF+(BUFSIZ*128) ; End of input buf addr
	XCHG			; Buffer end addr. in de
	LHLD	INPTR		; Current pointer in hl
	CALL	CPHL		; Test for end of buffer
	CZ	GETREC		; Yes, read disk records
	MOV	A,M		; Get byte
	INX	H		; Bump pointer
	SHLD	INPTR		; Save pointer
	ORA	A		; Clear carry
	JMP	SAVBT
;.....
;
;
; Save byte in line buffer
;
SAVBT:	LHLD	LPNT		; Get line pointer
	MOV	M,A		; Save byte
	INX	H		; Bump pointer
	SHLD	LPNT		; Save pointer
	CALL	LWRUPR		; Convert lower to upper case
	STA	CHAR		; Save char in char
	RET
;.....
;
;
GETREC:	LDA	CONSOLE		; Console on ?
	ORA	A
	JNZ	GTREC1		; Then he sees progress
	LHLD	LCNT		; Line-count
	CALL	DECOT		; Into ASCII
	LXI	D,DECERA	; Erase area
	CALL	PSOUT
	LXI	D,DEC		; ASCII linecount
	CALL	PSOUT		; To show progress
;
GTREC1:	MVI	B,BUFSIZ	; Number of sectors to read
	LXI	H,TBUF		; Get address of disk input buffer
	SHLD	IDADDR		; Initialize current buffer address
;
GETRC2:	LHLD	IDADDR		; Get addr of input buffer
	XCHG			; Put it in DE
	LXI	H,128		; Add 128 to input buf
	DAD	D		; Addr for read after next
	SHLD	IDADDR		; Save it read after next
	PUSH	B		; Save sector count
	PUSH	D		; Save current ptr in case EOF occurrs
	MVI	C,SETDMA	; Point to input buffer...
	CALL	BDOS
	MVI	C,READ		; Read code
	LXI	D,TFCB		; FCB address
	CALL	BDOS		; Issue read
	POP	D		; Restore current buf pointer
	POP	B		; Restore sector count
	CPI	00		; Error?
	JNZ	GETRC4		; Yes
	DCR	B		; Read all of the sectors?
	JNZ	GETRC2		; No, continue reading

GETRC3:	LXI	H,TBUF		; Reset buffer pointer
	SHLD	INPTR
	RET			; Return to caller
;...
;
;
GETRC4:	XCHG			; Point to first char past buf
	MVI	M,26H		; Put two...
	INX	H		; Control z's
	MVI	M,26H		; After last rec in file
	JMP	GETRC3		; Go reset buffer pointer
;.....
;
;
; Converts lower to upper case
; input: a=byte(upper/lower
; outputs: a=byte upper
;
LWRUPR:	CPI	'A'+20H		; Is it upper case?
	CMC			; Complement carry
	RNC			; Yes, return with carry reset
	CPI	'Z'+21H		; Over lower case 'z'?
	RNC			; No, return no carry
	SUI	20H		; Convert to upper case
	RET
;.....
;
;
;PSOUT prints string in D
;
PSOUT:	MVI	C,PSTRING
	CALL	BDOS		; Print String
	RET
;.....
;
;
; Routine to compare HL vs DE
; output: HL=DE, zero=on
;	  HL<>DE, zero=off
;
CPHL:	MOV	A,H
	CMP	D
	RNZ
	MOV	A,L
	CMP	E
	RET
;.....
;
;
; DATA
;
EMSG1:	DB	CR,LF,'Label table error',CR,LF,'$'
EMSG2:	DB	CR,LF,'Failed to delete existing cross reference file'
	DB	CR,LF,'$'
EMSG3:	DB	CR,LF,'Failed to create cross reference file',CR,LF,'$'
EMSG4:	DB	CR,LF,'Disk write failed - Out of space?',CR,LF,'$'
EMSG5:	DB	CR,LF,'Close failed on disk cross reference file'
	DB	CR,LF,'$'
EMSG6:	DB	CR,LF,'++ERROR++ Not enough memory for label table'
	DB	CR,LF,'$'
EMSG7:	DB	CR,LF,'++ERROR++ Label table overflow?',CR,LF,'$'
DONEMSG:DB	CR,LF,'Cross-reference list is done',CR,LF,'$'
NOLABS:	DB	CR,LF,'No Labels in this Program'
CONCRLF:DB	CR,LF,'$'
OFCB:	DB	0		; Disk output FCB, default drive
	DS	8		; File name
	DB	'XRF'		; File type
	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DCHAR:	DW	DISKBUF		; Pointer for disk buffer
BUFADR:	DS	2		; Pointer to disk output buffer for dma
IDADDR:	DS	2		; Pointer to disk input buffer for dma
DSKCNT:	DW	BUFSIZ*128	; Number of char left in disk buffer
INPTR:	DW	TBUF+(BUFSIZ*128) ; Pointer to char in input buffer
DISKBUF:DS	BUFSIZ*128	; Output disk buffer
TBUF:	DS	BUFSIZ*128	; Disk input buffer
;
;
CHAR:	DS	1
COL:	DS	1
FROM:	DS	2		; Move pointer
LAB:	DS	2		; Current label table address
LABBT:	DS	2		; Label table bottom address
LABTP:	DS	2		; Label table top address
LCNT:	DS	2		; Line counter
LIMIT:	DS	2		; Limit pointer
LINLAB:	DS	1		; 0 if first label on line
LPNT:	DS	2
REF:	DS	2		; Current reference table address
REFBT:	DS	2		; Reference table bottom address
REFTP:	DS	2		; Reference table top address
TO:	DS	2		; To pointer
DEC:	DS	5
	DB	'$'
;
DECERA:	DB	BS,BS,BS,BS,BS,'$' ; Erase string for Line-Nr display
PBUF:	DS	132
LABCT:	DS	1
LABPT:	DS	2
SBUF:	DS	LABSIZ		; Label buffer
NLINS:	DB	0		; Buffers to print on line
LINES:	DB	0		; Print line count
;
CONSOLE:DB	0		; Console output switch
DISKOUT:DB	0		; Disk output switch
LISTFLG:DB	0		; 0=no source listing
FTPRN:	DB	1		; Prn file type
TEMP:	DS	2		; Temp save word
	DS	64		; Stack can have up to 32 addresses
STACK	EQU	$
;.....
;
;
; Label table area
;
; The label table must be the last byte before ONCE ONLY CODE - XREF
; is NOT RESTARTABLE
;
;
	ORG	$
;
;
LABT:	DB	0FFH
;
LOGO:	DB	CR,LF,'CP/M assembler cross-reference list v27'
	DB	CR,LF,'$'
;
MSG1:	DB	'   disk cross-reference file exists, keep it (y/n) ? '
	DB	'$'
;
MSG2:	DB	'   like to have a line-numbered .XRF listing (y/n) ? '
	DB	'$'
;
EMSG0:	DB	CR,LF,'++ Can''t find that file ++',CR,LF,'$'
;
;
;
HELP:	DB	CR,LF,'This program can be used to create a cross-'
	DB	'reference listing',CR,LF,'of CP/M assembler programs.'
	DB	'  The input can be either the assembler',CR,LF
	DB	'language source code (FILENAME.ASM) or the assembly '
	DB	'listing (FILENAME.PRN).',CR,LF
	DB	'The output can be printed on the CP/M list device, '
	DB	'displayed on',CR,LF
	DB	'the CRT, or written to disk (file type will be '
	DB	'.XRF).  It is',CR,LF,'invoked by keying:',CR,LF,LF
	DB	09H,'XREF FILENAME.ASM      (Output on list device)'
	DB	CR,LF,09H,'XREF FILENAME.PRN CRT  (Output on the '
	DB	'CRT)',CR,LF,09H,'XREF FILENAME.ASM D    (Output on '
	DB	'disk-default drive)',CR,LF,09H,'XREF FILENAME.PRN B:D'
	DB	'  (Output on disk-drive specified)'
	DB	CR,LF,CR,LF,CR,LF,CR,LF,CR,LF,'$'
;.....
;
;
; Setup or initialization
;
SETUP:	LXI	D,LOGO		; Get program logo messagew
	CALL	PSOUT		; Display it
	LDA	TFCB+1		; Get first character of file name
	CPI	' '
	JZ	SETUP0
	CPI	'?'		; Help function?
	JNZ	SETUP1		; No, go check input file type
;
SETUP0:	LXI	D,HELP		; Display help message
	JMP	FERR1
;...
;
;
SETUP1:	MVI	A,0
	STA	LISTFLG		; No listing
	LDA	TFCB+9		; Get first character of file type
	CPI	'P'		; Is it type .PRN?
	JNZ	SETUP2		; No, don't set switch
	LDA	TFCB+10		; Get 2nd character of file type
	CPI	'R'
	JNZ	SETUP2
	LDA	TFCB+11		; Get 3rd character of file type
	CPI	'N'
	JNZ	SETUP2
	XRA	A
	STA	FTPRN		; Turn on .PRN file type
;
SETUP2:	LDA	TFCB+17		; Get 1st character of 2nd FCB
	CPI	'C'		; Output to console?
	JNZ	SETUP3		; No, don't turn on switch
	LDA	TFCB+18		; Get 2nd character of 2nd FCB
	CPI	'R'		; Output to CRT?
	JNZ	SETUP3		; If not, exit
	MVI	A,0FFH		; else turn on CRT
	STA	CONSOLE
	JMP	SETUP5		; Go open input file
;
SETUP3:	LDA	TFCB+17		; Get 1st character of 2nd FCB
	CPI	'D'		; Output to be written to disk?
	JNZ	SETUP5		; If not, exit
	MVI	A,0FFH
	STA	DISKOUT		; Turn on disk output switch
	LDA	TFCB+16		; Get output file drive number
	STA	OFCB		; Move to output FCB
	LXI	D,TFCB		; Point to FCB
	CALL	FOPEN		; Open disk input file
	LXI	D,TFCB+1	; Point to input file name
	MVI	B,8		; Length of file name
	LXI	H,OFCB+1	; Point to output FCB file name
	CALL	MOVE		; Move input file name to output FCB
	LXI	D,OFCB		; Does output file already exist?
	MVI	C,OPEN
	CALL	BDOS
	CPI	0FFH		; Open succeed?
	JZ	SETUP4		; No, file does not exist
	LXI	D,OFCB		; Close...
	MVI	C,CLOSE		; The open...
	CALL	BDOS		; File.
;
	LXI	D,MSG1		; Want to keep the old file?
	CALL	PSOUT
	MVI	C,CONIN		; Get the answer
	CALL	BDOS
	ANI	05FH		; Make upper case
	CPI	'Y'		; Operator say yes, keep it?
	JZ	BOOT		; If, yes, exit, done
	LXI	D,CONCRLF	; Write CRLF to console
	CALL	PSOUT
	LXI	D,OFCB		; Point to FCB to delete file
	MVI	C,DELETE	; Delete the file
	CALL	BDOS
	CPI	0FFH		; Delete succeed?
	LXI	D,EMSG2		; If not, show error message
	JZ	FERR1
;
SETUP4:	LXI	D,OFCB		; Point to output FCB
	MVI	C,MAKE		; Create new...
	CALL	BDOS		; Cross reference file.
	CPI	0FFH		; Create succeed?
	LXI	D,EMSG3		; Get err msg in case of failure
	JZ	FERR1		; Create failed, print msg & quit
	LXI	H,DISKBUF	; Get addr of disk buffer
	SHLD	DCHAR		; Init disk char pointer
;
SETUP5:	LXI	D,TFCB		; Point to fcb
	CALL	FOPEN		; Open fcb
	LXI	D,MSG2		; "Want Listing.."
	CALL	PSOUT
	MVI	C,CONIN
	CALL	BDOS		; Get answer
	ANI	05FH		; Make upper case
	CPI	'Y'
	JNZ	SETUP6		; No listing
	MVI	A,0FFH
	STA	LISTFLG		; Wants listing
;
SETUP6:	LXI	D,CONCRLF	; Write CRLF to console
	CALL	PSOUT
	LXI	H,PBUF
	SHLD	LPNT		; Set print pointer
	LXI	H,00001		; Set line counter...
	SHLD	LCNT		; To one.
	LXI	H,LABT		; Get address of label table
	SHLD	LAB
	SHLD	LABBT
	SHLD	LABTP		; Set label table pointers
	LHLD	MEMSZ		; Get available memory address
	DCX	H
	SHLD	REF
	SHLD	REFBT
	SHLD	REFTP		; Set reference table pointers
	RET
;.....
;
;
	END	START
