
; To save the game in CP/M, first quit the game.
; Then type:
; A> SAVE 136 GAME.COM

; TRS-80 Model I ALT-CP/M 1.4:
; z88dk-z80asm.exe -b -DALTCPM -DNO_ECHO -oBLACKS.COM blackstar.asm

; Standard CP/M
; z88dk-z80asm.exe -b -DNO_ECHO -DNEED_CRLF -oBLACKS.COM blackstar.asm

; ZX Spectrum 48K
; z88dk-z80asm.exe -b -DSPECTRUM blackstar.asm


IF SPECTRUM
  ORG $7000
  DEFC WBOOT  = $0000
  DEFC LINLEN = 31
  ;DEFC LINLEN = 63
  DEFC CONS_ROWS = 22
ELSE
 IF ALTCPM
  ORG $4300
  DEFC WBOOT  = $4200
  DEFC BDOS   = $4205
  DEFC LINLEN = 63
  DEFC CONS_ROWS = 16
 ELSE
  ORG $0100
  DEFC WBOOT  = $0000
  DEFC BDOS   = $0005
  DEFC LINLEN = 79
  DEFC CONS_ROWS = 24
 ENDIF
ENDIF



; STORAGE AREAS AND BUFFERS


  JP RUNB

IF !SPECTRUM
defs 800
ENDIF

BUFFERS:

XNCO:
  DEFB $00                ; 1st Optional Message
XBEFA:
  DEFB $00                ; 2nd Optional Message
LSTOBJ:
  DEFB $01                ; Byte reserved for latest object name
  DEFB $00
BUFFER:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; 60 byte line buffer
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

L7043:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00
L7057:
  DEFB $00
L7058:
  DEFW L7043
BLK4:
  DEFB $00,$00,$00,$00    ; Temporary buffer
CODBUF:
  DEFB $00                ; Coded text store & batch buffer
  DEFB $00
L7060:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
CODB2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; 2nd buffer for 'AGAIN
  DEFB $00,$00,$00,$00,$00,$00,$00
WAYOUT:
  DEFB $00,$00            ; Temporary store for available exits
RANSEED1:
  DEFB $00
RANSEED2:
  DEFB $00
CCOUNT:
  DEFB $00,$00,$00,$00,$00
SAVIX:
  DEFB $00,$00
L7087:
  DEFB $00,$00
MSGFLAG:
  DEFB $00
L708A:
  DEFB $02
L708B:
  DEFB $FF
CAPITAL_FLG:
  DEFB $00                ; First character in a sentence will uppercase
L708D:
  DEFB $00,$00,$00,$00,$00,$00

; Data block at 7093
GAME_BUFFERS:
  DEFW $0000

; Data block at 7095
GAME_SIZE:
  DEFW 184

; Data block at 7097
CURRENT_GAME:
  DEFW $0000

;
; MAIN game interpreter entry
;

RUNB:

IF SPECTRUM
  DI
ENDIF

  LD HL,(OBPROP)         ; $1CB7   $8C30
  LD DE,(GAME_BASE)      ; $1B34   $8AAD
  OR A
  SBC HL,DE
  INC HL                 ; +1
  LD (GAME_SIZE),HL
  LD B,H
  LD C,L

  LD HL,BUFFERS
  DEC HL

  LD (GAME_BUFFERS),HL
  EX DE,HL
  LD HL,(OBPROP)
  LDDR

  LD (CURRENT_GAME),DE
  LD BC,(GAME_SIZE)
  LD HL,(OBPROP)
  LDDR
  EX DE,HL

;
; First section prints out title info and sets up random number.
;

IF SPECTRUM
 IF ORIGINAL
  LD SP,$F800
  ;LD HL,$F700   ; FONT was at $F800
  LD HL,$3C00   ; ROM FONT (at $3D00)
  LD ($5C36),HL
 ENDIF
  LD A,$02
  CALL $1601
  CALL $0D6B
  LD A,$02
  CALL $1601
;ELSE
;  LD SP,$8800
ENDIF

  LD HL,(OBJDES)
  CALL MPRINT
  LD A,R
  LD (RANSEED1),A
  CALL CHRIN

IF SPECTRUM
  LD A,$02
  CALL $1601
  CALL $0D6B      ; Clear screen
ENDIF

  LD D,$14
  LD E,$00
  CALL GOTOXY
  XOR A
  LD (L708A),A

RUN:
  CALL DESCR
AFTDK:
  CALL STABLE
  CALL IBTCH
  JR Z,GTENTR
  CALL BEFA
GTENTR:
  CALL ENTRI
  LD A,R
  LD (RANSEED2),A
SRTOUT:
  LD IX,(FLAG)
  LD HL,CODBUF+1
  LD A,(HL)
  CP $FB
  JR NZ,QWOP
  LD A,(BUFFER-1)
  OR A
  JP Z,L71DB
  LD (HL),A
  JR L7135

QWOP:
  LD HL,(GAME_BASE)
  CP (HL)
  JR NC,L7135
  CP $80
  JR C,L7135
  LD (BUFFER-1),A
L7135:
  LD HL,CODBUF
  LD A,(HL)
  CP $0D
  JR NC,XMATCH_0
  LD DE,(WAYOUT)
MOREDI:
  LD A,(DE)
  CP $FF
  JR Z,XMATCH_0
  LD A,(DE)
  INC DE
  CP (HL)
  JR Z,DFND
  INC DE
  JR MOREDI
DFND:
  LD A,(DE)
  CP $F9
  JR NZ,BASL
  LD A,(IX+$14)
BASL:
  PUSH AF
  LD A,(IX+$0E)
  LD (IX+$14),A
  POP AF
  LD (IX+$0E),A
  LD (HL),$0D
  JP XMATCH_0
IBTCH:
  PUSH HL
  LD HL,CODBUF
IBTPL:
  LD A,(HL)
  OR A
  JR Z,NBTCH
  CP $FA                  ; THEN EQU 250  ; Don't alter this. Duplicate in
  JR Z,ZBTCH              ; database.
  INC HL
  JR IBTPL
ZBTCH:
  LD A,$FF
NBTCH:
  INC A
  POP HL
  RET
XMATCH_0:
  LD IX,CODBUF
  LD A,(L798A)
  OR A
  JR NZ,L718A
  LD IY,(TAB1)
  JR XMATCH
L718A:
  LD IY,(MSG)
  XOR A
  LD (L798A),A
  JR ENCHK_1
XMATCH:
  EXX
  LD HL,(OBPROP)
FLNA:
  INC HL
  LD A,(HL)
  OR A
  JP Z,ENCHK
  CP (IX+$01)
  JP Z,FNBYTE       ; got as match
FLNB:
  INC HL            ; otherwise skip to next
  LD A,(HL)
  OR A
  JP NZ,FLNB
  JP FLNA
FNBYTE:
  INC HL
  LD A,(HL)
  OR A
  JP Z,ILEGL
  CP (IX+$00)       ; check is legal
  JP Z,ENCHK
  JP FNBYTE
ILEGL:
  EXX
  LD HL,(_MSG)
  LD B,46           ; otherwise may not.
  JP HOPM

ENCHK:
  EXX
ENCHK_1:
  LD A,(IX+$01)     ;Save this byte
  LD (SAVIX),A
  LD DE,$0000       ;Reset pointers
NEXTK:
  LD A,(SAVIX)
  LD (IX+$01),A
  LD A,(IY+$00)
  OR A
  JR NZ,NOTENDM
L71DB:
  LD HL,CODBUF
  LD A,(HL)
  CP 13             ; (was 15) see if this was a direction
  JP Z,RUN
  LD HL,(_MSG)
  JR NC,DNFOL
  LD B,21           ; Print 'not valid direction'
  JP HOPM
DNFOL:
  LD B,20           ; 'don't follow you'
HOPM:
  CALL MFETCH
HOMU:
  JP AFTDK

NOTENDM:
  LD A,(IY+$00)
  CP $FF
  JR Z,CHSND
  CP (IX+$00)
  JR NZ,L720E
CHSND:
  LD A,(IY+$01)
  CP $FF
  JR Z,FAILTHS
  CP (IX+$01)
  JR Z,FAILTHS
L720E:
  INC IY
  LD A,(IY+$01)
  CP $FE
  JR NZ,L721D
  INC IY
  INC IY
  JR NOTENDM
L721D:
  INC IY
  LD A,(IY+$00)
  CP $FF
  JR NZ,L721D
  INC IY
  JP NEXTK
SKP1:
  INC IY
SKP1A:
  LD A,(IY+$00)
  CP $FE
  JR C,SKP1
  JR Z,FAILOOP
  INC IY
  JP NEXTK
FAILTHS:
  INC IY
FAILOOP:
  INC IY
FAILLX:
  LD A,(IY+$00)
  CP $FD
  JP Z,ACTONIT
  CP $FE
  JR NZ,L724F
  INC IY
  JR FAILTHS
L724F:
  CP $16
  JR NZ,L725D
  LD A,(IY+$01)
  CP (IX+$01)
HOPZ:
  JR Z,FAILTHS
  JR SKP1
L725D:
  CP $17
  JR NZ,L7269
  LD A,(IY+$01)
  CP (IX+$02)
  JR HOPZ
L7269:
  CP $18
  JR NZ,ISNC3
  LD A,(IY+$01)
  CP (IX+$01)
HOPNZ:
  JR NZ,FAILTHS
  JR SKP1
ISNC3:
  CP $19
  JR NZ,L7283
  LD A,(IY+$01)
  CP (IX+$02)
  JR HOPNZ
L7283:
  CP $1B
  JR NZ,L7291
  LD A,(IX+$00)
L728A:
  CP (IY+$01)
  JR NC,FAILTHS
  JR SKP1
L7291:
  CP $1E
  JR NZ,L729A
  LD A,(IX+$01)
  JR L728A
L729A:
  CP $1C
  JR NZ,L72A9
  LD A,(IX+$00)
L72A1:
  CP (IY+$01)
  JR C,FAILTHS
  JP SKP1
L72A9:
  CP $1F
  JR NZ,ISCL
  LD A,(IX+$01)
  JR L72A1
ISCL:
  CP $01
  JR NZ,ISNCL
  LD HL,(FL14)
  LD A,(HL)
  CP (IY+$01)
  JR HOPZ
ISNCL:
  CP $02
  JR NZ,L72CC
  LD HL,(FL14)
  LD A,(HL)
  CP (IY+$01)
  JR HOPNZ
L72CC:
  CP $20
  JR NZ,L72EC
  LD HL,(FL14)
L72D3:
  LD A,(IY+$01)
  INC IY
  CP $FD
  JP NC,ACTONIT
  CP (HL)
  JR NZ,L72D3
L72E0:
  LD A,(IY+$00)
  CP $FD
  JP NC,SKP1A
  INC IY
  JR L72E0
L72EC:
  CP $1D
  JR NZ,ISOPP
  LD HL,(FL14)
L72F3:
  LD A,(IY+$01)
  CP $FD
  JP NC,SKP1
  INC IY
  CP (HL)
  JR NZ,L72F3
L7300:
  LD A,(IY+$00)
  CP $FD
  JP NC,ACTONIT
  INC IY
  JR L7300
ISOPP:
  CP $11
  JP NC,ISRND
  LD A,(IY+$01)
  OR A
  JR NZ,L7326
  LD A,(IX+$01)
  LD D,A
  OR A
  JR NZ,L7327
  LD HL,(_MSG)
  LD B,$21
  JP HOPM
L7326:
  LD D,A
L7327:
  CALL FINDMS
  JR NZ,L7334
  LD HL,(_MSG)
  LD B,$19
  JP HOPM
L7334:
  LD D,(HL)
  LD A,(IY+$00)
  CP $03
  JR NZ,L7350
  LD HL,(FL14)
  LD A,(HL)
  CP D
  JP Z,FAILTHS
  LD A,$FE
  CP D
  JP Z,FAILTHS
  LD A,$FD
HOPZ1:
  CP D
  JP HOPZ
L7350:
  CP $04
  JR NZ,ISOW
  LD A,$FE
  JR HOPZ1
ISOW:
  CP $05
  JR NZ,ISOH
  LD A,$FD
  JR HOPZ1
ISOH:
  CP $07
  JR NZ,ISOWC
  LD HL,(FL14)
  LD A,(HL)
  JR HOPZ1
ISOWC:
  CP $06
  JR NZ,ISONP
  LD A,$FE
  CP D
  JP Z,FAILTHS
  DEC A
L7375:
  JR HOPZ1
ISONP:
  CP $08
  JR NZ,ISONC
  LD HL,(FL14)
  LD A,(HL)
  CP D
  JP Z,SKP1
  LD A,$FE
  CP D
  JP Z,SKP1
  LD A,$FD
HOPNZ1:
  CP D
  JP HOPNZ
ISONC:
  CP $09
  JR NZ,ISONW
  LD A,$FE
  JR HOPNZ1
ISONW:
  CP $0A
  JR NZ,ISNWC
  LD A,$FD
  JR HOPNZ1
ISNWC:
  CP $0B
  JR NZ,ISONH
  LD A,$FE
  CP D
  JP Z,SKP1
  DEC A
  JR HOPNZ1
ISONH:
  CP $0C
  JR NZ,ISOE
  LD HL,(FL14)
  LD A,(HL)
  JR HOPNZ1
ISOE:
  CP $0D
  JR NZ,ISONE
  LD A,$FF
  JR HOPNZ1
ISONE:
  CP $0E
  JR NZ,IS_L
  LD A,$FF
  JP HOPZ1
IS_L:
  CP $0F
  JR NZ,ISN_L
  LD A,(IY+$02)
  CP D
  INC IY
  JP HOPZ
ISN_L:
  LD A,(IY+$02)
  CP D
  INC IY
  JP HOPNZ
ISRND:
  CP $11
  JR NZ,ISTF
RANDOM:
  CALL RANM
  CP (IY+$01)
  JP C,FAILTHS
  JP SKP1
ISTF:
  PUSH DE
  LD HL,(FLAG)
  LD E,(IY+$01)
  LD D,$00
  ADD HL,DE
  POP DE
  CP $12
  JR NZ,ISNTF
  LD A,(HL)
  CP (IY+$02)
  INC IY
  JP HOPZ
ISNTF:
  CP $13
  JR NZ,ISLT
  LD A,(HL)
  CP (IY+$02)
  INC IY
  JP HOPNZ
ISLT:
  CP $14
  JR NZ,ISGE
  LD A,(HL)
  CP (IY+$02)
  INC IY
  JP Z,FAILTHS
  JP NC,FAILTHS
  JP SKP1
ISGE:
  CP $15
  JR NZ,DANGER
  LD A,(HL)
  CP (IY+$02)
  INC IY
  JP C,FAILTHS
  JP SKP1
DANGER:
  LD HL,(_MSG)
  LD B,$1A
  CALL MFETCH
  JP SKP1
ACTONIT:
  INC IY
  LD A,(IY+$00)
  CP $FE
  JR C,ACTO1
  INC IY
  JP NZ,NEXTK
  JP FAILLX
ACTO1:
  CP $80
  JR NZ,L7475
  LD A,(IY+$01)
  LD (IX+$00),A
  PUSH HL
  PUSH DE
  LD DE,CODBUF+1
  LD HL,L7060
L7463:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC DE
  OR A
  JR NZ,L7463
  POP DE
  POP HL
  LD A,(IX+$01)
  LD (SAVIX),A
  JP HOPC
L7475:
  CP $81
  JR NZ,L749B
  LD HL,(FLAG)
  INC HL
  INC HL
  LD (HL),$00
  LD HL,(FL14)
  LD B,(HL)
  LD HL,(GAME_BASE)
  INC HL
  LD DE,$0005
L748B:
  LD A,(HL)
  OR A
  JR Z,ACTONIT
  CP $FD
  JR C,L7498
  CP $FF
  JR NC,L7498
  LD (HL),B
L7498:
  ADD HL,DE
  JR L748B
L749B:

IF SPECTRUM
  CP $83
  JR NZ,L74BF
  CALL ASK_CONFIRM
  JP NZ,RUN
  CALL INIT_FILE
  EI
  CALL $04C2              ; SA-BYTES
  DI
  JP ACTONIT

INIT_FILE:
  LD IY,$5C3A
  LD DE,(GAME_SIZE)
  LD IX,(GAME_BASE)
  LD A,$FF
  OR A
  RET

L74BF:
  CP $89
  JR NZ,L74D5
  CALL ASK_CONFIRM
  JP NZ,RUN
  CALL INIT_FILE
  SCF
  EI
  CALL $0802              ; LD-BYTES
  DI
  JP RUN
ENDIF

L74D5:
  CP $84
  JR NZ,NO_RESTART
  LD HL,(GAME_BUFFERS)
INIT:
  CALL ASK_CONFIRM
  JP NZ,RUN
  LD BC,(GAME_SIZE)
  LD DE,(OBPROP)
RESTORE:
  LDDR
  LD B,$1D
  LD HL,(_MSG)
  CALL MPRINT
  JP RUN
NO_RESTART:
  CP $87
  JR NZ,NO_SAVEPOINT
  CALL ASK_CONFIRM
  JP NZ,RUN
  LD BC,(GAME_SIZE)
  LD DE,(CURRENT_GAME)
  LD HL,(OBPROP)
  JR RESTORE
NO_SAVEPOINT:
  CP $88
  JR NZ,NO_RESTORE
  LD HL,(CURRENT_GAME)
  JR INIT
NO_RESTORE:
  CP $17
  JR NZ,LB24
  LD A,(IY+$01)
  LD (XNCO),A
HOPC:
  INC IY
  JP ACTONIT
LB24:
  CP $1D
  JR NZ,APF
  LD A,$01
  LD (MSGFLAG),A
  JP RUN
APF:
  CP $1A
  JR NZ,ASMB
  PUSH HL
  PUSH IX
  LD E,(IY+$01)
  LD HL,(FLAG)
  LD D,$00
  ADD HL,DE
  PUSH HL
  POP IX
  CALL PNUMBER
  POP IX
  POP HL
  JR HOPC
ASMB:
  CP $18
  JR NZ,AWT
  LD A,(IY+$01)
  LD (XBEFA),A
  JR HOPC
AWT:
  CP $19
  JR NZ,AINV
  LD A,(IY+$01)
  LD B,A
WTLP:
  PUSH BC
  LD B,$FF
WTLP1:
  PUSH BC
  LD B,$FF
LZL0:
  PUSH AF
  POP AF
  PUSH AF
  POP AF
  DJNZ LZL0
  POP BC
  DJNZ WTLP1
  POP BC
  DJNZ WTLP
  JR HOPC
AINV:
  CP $01
  JR NZ,ALA
  CALL ICANC
  JP ACTONIT
ALA:
  CP $16
  JR NZ,AEX
  CALL ICANC_2
  JP ACTONIT
AEX:
  CP $10
  JR NZ,AQT
  CALL IBTCH
  JP AFTDK
AQT:
  CP $0D
  JR NZ,AOK
  LD HL,(_MSG)
  LD B,$1B
  CALL MFETCH
  PUSH IX
  LD IX,(FL13)
  CALL PNUMBER
  POP IX
  LD B,$1C
  CALL MFETCH
  CALL ASK_CONFIRM
  JP NZ,RUN
  JP WBOOT
AOK:
  CP $0C
  JR NZ,ASC
  CALL IBTCH
  JP Z,AFTDK
  LD HL,(_MSG)
  LD B,$1D
  JP HOPM
ASC:
  CP $11
  JR NZ,AMV
  LD HL,(_MSG)
  PUSH IX
  PUSH IY
  PUSH DE
  LD B,$1E
  CALL MFETCH
  POP DE
  POP IY
  POP IX
  PUSH IX
  LD IX,(FL13)
  CALL PNUMBER
  POP IX
  CALL CRLF
  JP ACTONIT
AMV:
  CP $0B
  JR NZ,APR
  LD HL,(FL14)
  LD A,(IY+$01)
  CP $F9
  JR NZ,AMV1
  LD HL,(FL20)
  LD A,(HL)
AMV1:
  PUSH AF
  LD HL,(FL14)
  LD A,(HL)
  LD HL,(FL20)
  LD (HL),A
  LD HL,(FL14)
  POP AF
  LD (HL),A
  JP RUN
APR:
  CP $05
  JR NZ,APRM
  LD HL,(UMESS)
APRPL:
  LD B,(IY+$01)
  PUSH IX
  PUSH IY
  PUSH DE
  CALL MFETCH
  POP DE
  POP IY
  POP IX
  JP HOPC
APRM:
  CP $06
  JR NZ,AFLIP
L7632:
  LD HL,(_MSG)
  CALL RND_FLAG
  JR APRPL
AFLIP:
  LD HL,(FLAG)
  PUSH DE
  LD D,$00
  LD E,(IY+$01)
  ADD HL,DE
  POP DE
  CP $15
  JR NZ,AIN
  LD A,(HL)
  OR A
  JR NZ,MAKO
  LD A,$01
  JR MAKO1
MAKO:
  XOR A
MAKO1:
  LD (HL),A
  JP HOPC
AIN:
  CP $0E
  JR NZ,ADEF
  INC (HL)
  JP NZ,HOPC
  DEC (HL)
  JP HOPC
ADEF:
  CP $0F
  JR NZ,ASF
  LD A,(HL)
  OR A
  JR Z,L766B
  DEC (HL)
L766B:
  JP HOPC
ASF:
  CP $08
  JR NZ,LB41
  LD A,(IY+$02)
  LD (HL),A
  INC IY
  JP HOPC
LB41:
  CP $1B
  JR NZ,LB42
  LD B,(HL)
  XOR A
  LD (HL),A
  LD HL,(FLAG)
  LD D,$00
  LD E,(IY+$02)
  ADD HL,DE
  LD A,B
  ADD A,(HL)
  LD (HL),A
  JR NC,BXRL
BRBXA:
  LD (HL),$FF
BXRL:
  INC IY
  JP HOPC
LB42:
  CP $1C
  JR NZ,_ADL
  LD B,(HL)
  XOR A
  LD (HL),A
  LD HL,(FLAG)
  LD D,$00
  LD E,(IY+$02)
  ADD HL,DE
  LD A,(HL)
  SUB B
  LD (HL),A
  JR NC,BXRL
SEFAP:
  LD (HL),$00
SAFAP:
  INC IY
  JP HOPC
_ADL:
  CP $07
  JR NZ,ROBJ
  LD HL,(FL14)
  LD B,(HL)
  LD HL,(LOC)
  PUSH IX
  PUSH IY
  PUSH DE
  CALL MFETCH
  POP DE
  POP IY
  POP IX
  JP ACTONIT
ROBJ:
  LD A,(IY+$01)
  OR A
  JR Z,BMISTHS
  LD (IX+$01),A
  LD D,A
  JR MISSTHS
BMISTHS:
  LD A,(IX+$01)
  LD D,A
  OR A
  JR NZ,MISSTHS
  LD HL,(_MSG)
  LD B,$21
  JR ACDANX
MISSTHS:
  CALL FINDMS
  JR NZ,ALAXZ
  LD HL,(_MSG)
  LD B,$1F
ACDANX:
  JP HOPM
ALAXZ:
  LD D,(HL)
  JR ANOTX
ANOTX:
  LD A,(IY+$00)
  CP $09
  JR NZ,LB45
  INC HL
  INC HL
L7701:
  LD A,(HL)
  OR A
  JR Z,NODSC
  LD B,A
  LD HL,(UMESS)
  JR L7715
NODSC:
  DEC HL
  LD A,(HL)
  LD (LSTOBJ),A
  LD B,$04
  LD HL,(_MSG)
L7715:
  CALL MFETCH
  JP HOPC
LB45:
  CP $82
  JR NZ,L7729
  INC HL
  LD A,(HL)
  LD (LSTOBJ),A
  INC IY
  JP L7632
L7729:
  CP $0A
  JR NZ,AGET
  LD DE,$0005
  LD B,(HL)
  ADD HL,DE
  LD C,(HL)
  LD (HL),B
  OR A
  SBC HL,DE
  LD (HL),C
  JP HOPC
AGET:
  CP $02
  JR NZ,AWR
  CALL TOOMNY
  LD (HL),$FE
L7744:
  JR L774F
AWR:
  CP $03
  JR NZ,ADR
  CALL TOOMNY
  LD (HL),$FD
L774F:
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  LD (HL),$00
  JR NZ,L7762
  INC HL
  LD C,(HL)
  LD HL,(FL13)
  LD A,(HL)
  SUB C
  JR C,L7768
  JR L7769
L7762:
  LD HL,(FL13)
  ADD A,(HL)
  JR NC,L7769
L7768:
  XOR A
L7769:
  LD (HL),A
BRTSB:
  JP HOPC
ADR:
  CP $04
  JR NZ,APU
ADR1:
  PUSH IX
  LD IX,(FLAG)
  LD A,(IX+$0E)
  LD (HL),A
  CP (IX+$0B)
  JR NZ,L778B
  INC HL
  INC HL
  INC HL
  INC HL
  LD A,(IX+$0D)
  ADD A,(HL)
  LD (IX+$0D),A
L778B:
  POP IX
  JR BRTSB
APU:
  CP $12
  JR NZ,ACR
  LD A,(IY+$02)
  LD (HL),A
  INC IY
  JR BRTSB
ACR:
  CP $13
  JR Z,ADR1
  CP $14
  JR NZ,L77A7
  LD (HL),$FF
  JR BRTSB
L77A7:
  CP $85
  JR NZ,L77B8
  INC HL
  INC HL
  INC HL
  INC HL
  LD A,(HL)
L77B0:
  LD HL,(FL13)
  ADD A,(HL)
  LD (HL),A
  JP HOPC
L77B8:
  CP $86
  JR NZ,DANGA
  INC HL
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  NEG
  JR L77B0
DANGA:
  LD HL,(_MSG)
  LD B,$20
  JP HOPM
TOOMNY:
  PUSH IX
  LD IX,(FLAG)
  LD A,(IX+$02)
  ADD A,(IX+$12)
  CP (IX+$03)
  JR C,L77EF
  LD HL,(_MSG)
  LD B,$26
  CALL MFETCH
  POP IX
  POP IX
  DEC IY
  JP HOMU
L77EF:
  LD A,(IX+$0B)
  CP (IX+$0E)
  POP IX
  RET
ONCO:
  LD A,(XNCO)
  LD B,A
  XOR A
  LD (XNCO),A
  JP BEFAD
BEFA:
  LD A,(XBEFA)
  LD B,A
  XOR A
  LD (XBEFA),A
BEFAD:
  LD A,B
  OR A
  RET Z
  LD HL,(UMESS)
  JP MFETCH
PNUMBER:
  PUSH HL
  LD A,(IX+$00)
  LD HL,$0000
BM1:
  SUB $64
  JR C,BM2
  INC H
  JR BM1
BM2:
  ADD A,$64
BM3:
  SUB $0A
  JR C,BM4
  INC L
  JR BM3
BM4:
  ADD A,$0A
  PUSH AF
  LD A,H
  OR A
  JR Z,BM5
  CALL CCOUT
BM5:
  LD A,L
  CALL CCOUT
  POP AF
  CALL CCOUT
  POP HL
  RET
CCOUT:
  OR A
  ADD A,$30
  JP COUT
RANM:
  PUSH HL
  PUSH DE
  LD HL,(RANSEED1)
  LD D,H
  ADD HL,HL
  LD A,H
  ADD A,A
  XOR D
  BIT 7,A
  JR Z,L7854
  INC L
L7854:
  LD A,L
  LD (RANSEED1),HL
  POP HL
  POP DE
  RET
RND_FLAG:
  PUSH HL
  CALL RANM
  AND $01
  LD HL,(FL21)
  LD (HL),A
  XOR $01
  INC HL
  LD (HL),A
  POP HL
  RET
DESCR:
  LD IX,(FLAG)
  LD HL,(LOC)
  LD B,(IX+$0E)
  CALL MFETCH
  LD A,(IX+$10)
  OR A
  JR Z,EN1
  LD A,(MSGFLAG)
  OR A
  JR NZ,L7894
  LD A,(IX+$0C)
  OR A
  JR Z,L7894
  LD HL,(WAYOUT)
  DEC HL
  BIT 0,(HL)
  JR Z,EN1
  RES 0,(HL)
L7894:
  XOR A
  LD (MSGFLAG),A
  LD B,(IX+$0E)
  LD HL,(TABKEY)
  CALL MFETCH
EN1:
  CALL ICANC_2
  CALL ONCO
  RET
L78A8:
  PUSH HL
  LD D,$00
  LD E,$00
  CALL GOTOXY
  LD A,$20
  CALL CHROUT
  LD B,$0D
  LD HL,(FL16)
  LD A,(HL)
  OR A
  JR Z,L78DF
  LD HL,(L7087)
  CALL L7F0A
  CALL DECOMP_GETCHR
  LD A,(HL)
  RES 5,A
L78CA:
  OR A
  JR Z,L78DF
  CP $23
  JR Z,L78DF
  CP $3E
  JR Z,L78DF
  CALL CHROUT
  INC HL
  CALL DECOMP_GETCHR
  LD A,(HL)
  DJNZ L78CA
L78DF:
  LD A,$20
L78E1:
  CALL CHROUT
  DJNZ L78E1
  LD HL,TXT_SCORE
L78E9:
  LD A,(HL)
  OR A
  JR Z,L78F7
  CALL CHROUT
  INC HL
  JR L78E9
L78F3:
  XOR A
  LD (CCOUNT),A
L78F7:
  PUSH IX
  LD IX,(FL13)
  CALL PNUMBER
  LD A,$2F
  CALL CHROUT
  LD IX,(FL06)
  LD A,(IX+$00)
  OR A
  JR Z,L7912
  CALL PNUMBER
L7912:
  DEC IX
  CALL PNUMBER
  POP IX
  LD A,$20
  CALL CHROUT
  CALL CHROUT
  CALL CHROUT
  CALL CRLF
  LD B,$1E
  LD A,$20
L792B:
  CALL CHROUT
  DJNZ L792B
  LD D,$14
  LD E,$00
  POP HL
  JP GOTOXY
TXT_SCORE:
  DEFM "Score "
  DEFB $00
ENTRI:
  LD HL,CODBUF
  LD DE,CODBUF
  LD A,(HL)
  OR A
  JR Z,ENTRX
BUFFZ:
  LD A,(HL)
  INC HL
  OR A
  JR NZ,BUFFY
  LD HL,CODBUF
  LD (HL),A
  JR ENTRI
BUFFY:
  CP $FA
  JR NZ,BUFFZ
BUFFY1:
  LD A,(HL)
  INC HL
  CP $FA
  JR Z,BUFFY1
  DEC HL
  PUSH HL
  LD BC,$0001
XXLDR:
  LD A,(HL)
  OR A
  JR Z,XLDR
  INC HL
  INC BC
  JR XXLDR
XLDR:
  POP HL
  LDIR
  INC SP
  INC SP
  JP SRTOUT
ENTRX:
  CALL RND_FLAG
  LD HL,CODBUF
  XOR A
  LD (HL),A
  LD HL,BUFFER
  LD BC,$0000
  LD A,(L798A)
  OR A
  JR Z,L798B
  JP CON
L798A:
  DEFB $00
L798B:
  XOR A
  LD (L708A),A
  CALL CRLF
  CALL CRLF
  LD A,$3E
  CALL COUT
ENT1:
  LD A,$5F
  CALL CHROUT
  LD A,$08
  CALL CHROUT
  CALL CHRIN
  CP $0D
  JR Z,ENDIN
  CP $0C
  JR Z,BACKS
  CP $30
  JR Z,BACKS
  CP $31
  JR Z,ENT_AGAIN
  CP $07                  ; CTL-U (CAPS-SHIFT+1 on ZX Spectrum) = scrap line
  JR NZ,CONVUP
ENT_AGAIN:
  LD A,$2A
  CALL COUT
  JR ENTRX
CONVUP:
  CP $20                  ; Convert character to UPPERCASE
  JP C,ENT1
IF !NO_ECHO
  CALL CHROUT
ENDIF
  CP $20
  JR Z,MISTRP
  RES 5,A
  CP $41
  JR C,ENT1
MISTRP:
  LD (HL),A
  INC HL
  INC B
  LD A,B
  CP LINLEN-2
  JR NC,ENDIN
  JR ENT1
BACKS:
  LD A,B                  ; DEL/BS pressed, deal with backspace
  SUB $01
  JR C,BACKS_0
  LD B,A
  DEC HL
  LD A,$20
  CALL CHROUT
  LD A,$08
  CALL CHROUT
  LD A,$08
  CALL CHROUT
  JR ENT1
BACKS_0:
  LD A,$20
  CALL CHROUT
  JP L798B
ENDIN:
  LD (HL),$00             ; CR pressed, end of input phase
  LD A,$20
  CALL CHROUT
  CALL CRLF
  CALL CRLF
  LD A,B
  OR A
  JR NZ,CON
  JP ENTRI
CON:
  LD DE,BUFFER
  LD C,$00
  LD HL,CODBUF
MORC:
  LD A,(L798A)
  OR A
  JR NZ,L7A26
  LD IY,(TABKEY1)
  JR L7A2A
L7A26:
  LD IY,(TABKEY2)
L7A2A:
  CALL FIND1ST
  JR Z,ENDMESS
XX:
  LD B,(IY+$00)
  INC IY
  LD A,B
  XOR $55
  LD B,A
  OR A
  JR Z,MORC
MORXX:
  LD A,(IX+$00)
  CP (IY+$00)
  JR NZ,MISS
  LD A,(IX+$01)
  CP (IY+$01)
  JR NZ,MISS
  LD A,(IX+$02)
  CP (IY+$02)
  JR NZ,MISS
  LD A,(IY+$03)
  AND $7F
  CP (IX+$03)
  JR NZ,MISS
GOTONE:
  LD A,C                  ; is this the 1st word?
  OR A
  JR NZ,GHIR
  LD A,B
  CP $FC
  JR NZ,GHIR
  LD HL,CODB2
  LD DE,CODBUF
  LD BC,$000F
  JR LDIR_RET
GHIR:
  LD (HL),B
  INC HL
  LD C,$01
  JR MORC
MISS:
  LD A,(IY+$03)
  INC IY
  INC IY
  INC IY
  INC IY
  OR A
  JP M,XX
  JR MORXX
ENDMESS:
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD A,C
  OR A
  JR NZ,GOTALOT
  LD HL,(_MSG)
  LD B,$01
  CALL MFETCH
  JP ENTRI
GOTALOT:
  LD HL,CODBUF
  LD DE,CODB2
  LD BC,$000F
LDIR_RET:
  LDIR
  RET
FIND1ST:
  LD A,(DE)
  OR A
  RET Z
  CP $20
  JR NZ,L7AB5
  INC DE
  JR FIND1ST
L7AB5:
  PUSH HL
  LD IX,BLK4
  PUSH IX
  POP HL
  LD A,$75
  LD (IX+$00),A
  LD (IX+$01),A
  LD (IX+$02),A
  LD (IX+$03),A
  LD B,$04
PRP:
  LD A,(DE)
  OR A
  JR Z,FX
  CP $20
  JR Z,FX
  XOR $55
  LD (HL),A
  INC HL
  INC DE
  DJNZ PRP
BRT:
  LD A,(DE)
  OR A
  JR Z,FX
  CP $20
  JR Z,FX
  INC DE
  JR BRT
FX:
  CP $FF
  POP HL
  RET

GOTOXY:
  PUSH IY
  PUSH AF
  PUSH BC
  PUSH HL
  PUSH IX
  PUSH DE
IF SPECTRUM
  LD IY,$5C3A
  LD A,$02
  CALL $1601
  DI
  LD A,$16
  CALL CHROUT
  POP DE
  PUSH DE
  LD A,D
  CALL CHROUT
  LD A,E
  CALL CHROUT
ENDIF
  POP DE
  POP IX
  POP HL
  POP BC
  POP AF
  POP IY
  RET

CRLF:
  PUSH AF
  CALL L7BE4
  POP AF
L7B1A:
  PUSH IY
  PUSH AF
  PUSH BC
  PUSH HL
  PUSH IX
  PUSH DE
IF SPECTRUM
  LD IY,$5C3A
ENDIF
  XOR A
  LD (CCOUNT),A
  LD A,$0D
  CALL CHROUT
IF NEED_CRLF
  LD A,$0A
  CALL CHROUT
ENDIF
  CALL L7B3B
  POP DE
  POP IX
  POP HL
  POP BC
  POP AF
  POP IY
  RET

L7B3B:
  LD A,(L708A)
  INC A
  CP CONS_ROWS
  JR C,L7B63
  LD HL,TXT_MORE
L7B46:
  LD A,(HL)
  OR A
  JR Z,L7B50
  CALL CHROUT
  INC HL
  JR L7B46

L7B50:
  CALL CHRIN
  LD A,$08
  CALL CHROUT_10T
  LD A,$20
  CALL CHROUT_10T
  LD A,$08
  CALL CHROUT_10T
  XOR A
L7B63:
  LD (L708A),A
  RET

TXT_MORE:
  DEFM "<< MORE >>"
  DEFB $00

CHROUT_10T:
  LD B,$0A
CHROUT_10:
  CALL CHROUT
  DJNZ CHROUT_10
  RET

IF SPECTRUM
; ZX Spectrum ROM
CHRIN:
  PUSH IY
  PUSH BC
  PUSH HL
  PUSH IX
  PUSH DE
  LD IY,$5C3A
  EI
  CALL DELAY
CHRIN_0:
  CALL $028E
  LD C,$00
  JR NZ,CHRIN_0
  CALL $031E
  JR NC,CHRIN_0
  DEC D
  LD E,A
  CALL $0333
  AND $7F
  DI
  POP DE
  POP IX
  POP HL
  POP BC
  POP IY
  RET
ELSE
; CP/M -BDOS
CHRIN:
  PUSH IY
  PUSH BC
  PUSH HL
  PUSH IX
  PUSH DE
	LD	C,1
	CALL	BDOS		;CP/M I/O
  POP DE
  POP IX
  POP HL
  POP BC
  POP IY
  RET
ENDIF

IF SPECTRUM
DELAY:
  LD BC,24831
DELAY_0:
  DEC BC
  LD A,C
  OR B
  JR NZ,DELAY_0
  RET
ENDIF

COUT:
  PUSH AF
  LD A,(CCOUNT)
  CP LINLEN
  JR C,L7BBA
  CALL L7B1A
  XOR A
L7BBA:
  INC A
  LD (CCOUNT),A
  POP AF
  JR CHROUT

L7BC1:
  PUSH HL
  OR A
  JR NZ,L7BCA
  CALL L7BE4
  POP HL
  RET

L7BCA:
  PUSH AF
  LD A,(L7057)
  INC A
  LD (L7057),A
  LD HL,(L7058)
  POP AF
  LD (HL),A
  INC HL
  LD (L7058),HL
  CP $20
  JR NZ,L7BE2
  CALL L7BE4
L7BE2:
  POP HL
  RET

L7BE4:
  LD A,(L7057)
  OR A
  RET Z
  LD H,A
  LD A,(CCOUNT)
  ADD A,H
  CP LINLEN
  JR C,L7BF7
  CALL L7B1A
  JR L7BE4

L7BF7:
  LD (CCOUNT),A
  LD B,H
  LD HL,L7043
  LD (L7058),HL
PRINT_STR:
  LD A,(HL)
  INC HL
  CALL CHROUT
  DJNZ PRINT_STR
  XOR A
  LD (L7057),A
  RET

IF SPECTRUM

CHROUT:
  PUSH IY
  PUSH BC
  PUSH HL
  PUSH IX
  PUSH DE
  PUSH AF
  LD IY,$5C3A
  LD A,$10
  LD ($5C8C),A
  LD A,$02
  CALL $1601
  POP AF
  PUSH AF
  RST $10
  DI
  POP AF
  POP DE
  POP IX
  POP HL
  POP BC
  POP IY
  RET
;  RET              ; Useless extra RET in the original code

ELSE

CHROUT:
  PUSH IY
  PUSH BC
  PUSH HL
  PUSH IX
  PUSH DE
  PUSH AF
	LD	C,2
	LD	E,A
	CALL	BDOS
  POP AF
  POP DE
  POP IX
  POP HL
  POP BC
  POP IY
  RET

ENDIF



STABLE:
  LD IX,(FLAG)
  INC (IX+$04)
  INC (IX+$05)
  LD A,$64
  CP (IX+$05)
  JR NZ,L7C49
  LD (IX+$05),$00
  INC (IX+$06)
L7C49:
  LD HL,(FL06)
  LD B,$03
L7C4E:
  INC HL
  LD A,(HL)
  OR A
  JR Z,L7C54
  DEC (HL)
L7C54:
  DJNZ L7C4E
  LD A,(IX+$11)
  DEC A
  AND (IX+$0A)
  OR (IX+$01)
  LD (IX+$10),A
  LD A,(IX+$11)
  OR A
  JR NZ,STAB5
  LD A,(IX+$0A)
  SUB $01
  JR C,STAB5
  LD (IX+$0A),A
STAB5:
  LD B,$FE
  CALL STAB51
  LD B,$FD
  LD IX,(FL16)
  CALL STAB51
  LD IX,(FL14)
  LD B,(IX+$00)
  LD IX,(FL17)
STAB51:
  LD (IX+$02),$00
  LD HL,(GAME_BASE)
  INC HL
  LD DE,$0005
STAB5A:
  LD A,(HL)
  OR A
  JR Z,STAB6
  ADD HL,DE
  CP B
  JR NZ,STAB5A
  INC (IX+$02)
  JR STAB5A
STAB6:
  LD IX,(FLAG)
  RET
MFETCH:
  PUSH HL
  PUSH AF
  LD A,$00
LOOPF:
  PUSH BC
  LD BC,$0000
  CPIR
  POP BC
  DJNZ LOOPF
  LD A,$FF
  LD (L708B),A
  LD A,(HL)
  CP $FC
  JR C,MPRX
  CP $FE
  JR NC,MPML
  INC A
  INC A
  LD (IX+$01),$00
  JR MPM
MPML:
  LD (IX+$01),$01
MPM:
  LD (IX+$0F),A
  INC HL
  LD (WAYOUT),HL
BRPX:
  LD A,(HL)
  CP $FF
  INC HL
  JR Z,BLTX
  JR BRPX
BLTX:
  LD (L7087),HL
  LD A,(IX+$11)
  DEC A
  AND (IX+$0A)
  OR (IX+$01)
  LD (IX+$10),A
  LD (L708B),A
  JR MPRX

;
; HL-POINTS-TO-MESSAGE type of routine.
;
MPRINT:
  PUSH HL                ;save registers
  PUSH AF
MPRX:
  XOR A
  LD (L708D),A
  CALL L7F0A
MPRX_1:
  CALL DECOMP_GETCHR
  LD A,(HL)              ;get a character
  OR A                   ;test it
  JP Z,MPREND            ;No more, perhaps?
  INC HL                 ;ready for next char.

; <------ new code ------>
  CP $23                 ;
  JR NZ,L7D22            ; 
  PUSH DE                ; 
  LD B,$04               ; 
  LD DE,BUFFER           ; 
L7D10:                   ; 
  CALL DECOMP_GETCHR     ; 
  LD A,(HL)              ; 
  INC HL                 ; 
  LD (DE),A              ; 
  INC DE                 ; 
  DJNZ L7D10             ; 
  XOR A                  ; 
  LD (DE),A              ; 
  INC A                  ; 
  LD (L798A),A           ; 
  POP DE                 ; 
  JR L7D3F               ; 
L7D22:                   ; 
  LD D,A                 ; 
  LD A,(L708B)           ; 
  OR A                   ; 
  LD A,D                 ; 
  JR Z,MPRX_1            ; 
  CP $5D                 ; 
  JR NZ,L7D32            ; 
  XOR A                  ; 
  JP L7DE5               ; 
L7D32:                   ; 
  CP $5B                 ; 
  JR NZ,L7D3B            ; 
  LD (L708D),A           ; 
  JR MPRX_1              ; 
L7D3B:                   
; > -- ------------ -- <

  CP $3E            ; '>' Terminate batch?
  JR NZ,LB53
L7D3F:
  XOR A
  LD (CODBUF),A
  JR MPRX_1
LB53:
  CP $25            ; '%' looking for a CRLF?
  JR NZ,LB54
  CALL CRLF
  JR MPRX_1
LB54:

; <------ new code ------>
  CP $3C                  ;
  JR NZ,L7D79             ;
  PUSH HL                 ;
  LD HL,(COMP_PTR)        ;
  PUSH HL                 ;
  LD HL,(NIBBLE_TOGGLE)   ;
  PUSH HL                 ;
  LD HL,(EXPAND_PTR)      ;
  PUSH HL                 ;
  LD A,(LSTOBJ)           ;
  LD HL,(UMESS)           ;
  LD B,A                  ;
  CALL MFETCH             ;
  POP HL                  ;
  LD (EXPAND_PTR),HL      ;
  POP HL                  ;
  LD (NIBBLE_TOGGLE),HL   ;
  POP HL                  ;
  LD (COMP_PTR),HL        ;
  POP HL                  ;
  JP MPRX_1               ;
L7D79:                    ;
  CP $61                  ;
  JR C,L7D90              ;
  CP $7A                  ;
  JR NC,L7D90             ;
  LD A,(L708D)            ;
  OR A                    ;
  LD A,D                  ;
  JR NZ,L7DDA             ;
  LD (L708D),A            ;
  RES 5,A                 ;
  JP L7DDA                ;
L7D90:                    ;
  CP $2E                  ;
  JR NZ,L7D9B             ;
  XOR A                   ;
  LD (L708D),A            ;
  LD A,D                  ;
  JR L7DDA                ;
L7D9B:                    ;
; > -- ------------ -- <
  CP $7B
  JR NZ,LB55              ; '(' Starting new conditional?
  CALL DECOMP_GETCHR
  LD A,(HL)
  CP '/'                  ;Negative form?
  JR NZ,FRTHR             ;section added Feb. 1981 for negative flags.
  LD C,$FF
  CALL DECOMP_GETCHR
  JR FRTHR1
FRTHR:
  LD C,$00
FRTHR1:
  PUSH HL
  LD A,(HL)
  SUB 62
  LD D,$00
  LD E,A
  LD HL,(FL20)
  ADD HL,DE
  LD A,C
  OR A
  JR Z,L7DC5
  LD A,(HL)
  OR A
  JR NZ,L7DCE
  JR L7DC9
L7DC5:
  LD A,(HL)
  OR A
  JR Z,L7DCE
L7DC9:
  POP HL
  INC HL
  JP MPRX_1
L7DCE:
  POP HL
  CALL L7DEB
  JP MPRX_1
LB55:
  CP $7D              ; ')' Ending a conditional?
  JP Z,MPRX_1
L7DDA:
  CALL L7BC1
  JP MPRX_1
MPREND:
  CALL CRLF
  JR L7DE8
L7DE5:
  CALL L7BC1
L7DE8:
  POP AF
  POP HL
  RET

L7DEB:
  LD B,$01
L7DED:
  LD A,(HL)
  INC HL
  CP $7D
  JR Z,L7E01
  CP $7B
  JR NZ,L7DFD
  INC B
L7DF8:
  CALL DECOMP_GETCHR
  JR L7DED
L7DFD:
  OR A
  JR NZ,L7DF8
  RET
L7E01:
  DJNZ L7DED
  RET
ICANC_2:
  EXX
  PUSH IX
  LD IX,(FLAG)
  LD A,(IX+$10)
  OR A
  JR NZ,ICANQ
  LD B,$0F
  LD HL,(_MSG)
  CALL RND_MFETCH
  JR ICAN3
ICANQ:
  LD HL,(OBJLOC)
L7E1E:
  LD C,(IX+$0E)
  CALL L7EBC
  JR Z,ICAN3
  INC HL
  LD A,(HL)
  DEC HL
  LD (LSTOBJ),A
  LD B,$12
  PUSH HL
  LD HL,(_MSG)
  CALL RND_MFETCH
  POP HL
  JR L7E1E
ICAN3:
  POP IX
  EXX
  RET
ICANC:
  EXX
  PUSH IX
  LD IX,(FLAG)
  LD A,(IX+$10)
  OR A
  JR NZ,L7E53
  LD B,$0F
  LD HL,(_MSG)
  CALL RND_MFETCH
  JR L7EB2
L7E53:
  LD HL,(OBJLOC)
  LD C,$FE
  CALL L7EBC
  JR Z,L7E7A
  LD B,$10
  JR L7E6A
L7E61:
  LD C,$FE
  CALL L7EBC
  JR Z,L7E7E
  LD B,$03
L7E6A:
  INC HL
  LD A,(HL)
  DEC HL
  LD (LSTOBJ),A
  PUSH HL
  LD HL,(_MSG)
  CALL RND_MFETCH
  POP HL
  JR L7E61
L7E7A:
  LD B,$11
  JR L7E80
L7E7E:
  LD B,$05
L7E80:
  LD HL,(OBJLOC)
  LD C,$FD
  CALL L7EBC
  JR Z,L7EA5
  JR L7E95
L7E8C:
  LD C,$FD
  CALL L7EBC
  JR Z,L7EB2
  LD B,$03
L7E95:
  INC HL
  LD A,(HL)
  DEC HL
  LD (LSTOBJ),A
  PUSH HL
  LD HL,(_MSG)
  CALL RND_MFETCH
  POP HL
  JR L7E8C
L7EA5:
  LD A,B
  CP $11
  JR NZ,L7EB2
  LD B,$02
  LD HL,(_MSG)
  CALL RND_MFETCH
L7EB2:
  POP IX
  EXX
  RET
RND_MFETCH:
  CALL RND_FLAG
  JP MFETCH
L7EBC:
  PUSH DE
  LD DE,$0005
L7EC0:
  ADD HL,DE
  LD A,(HL)
  OR A
  JR Z,L7EC9
  CP C
  JR NZ,L7EC0
  OR A
L7EC9:
  POP DE
  RET
ASK_CONFIRM:
  PUSH HL
  LD HL,YES_NO
  LD B,$08
  CALL PRINT_STR
  CALL CHRIN
  RES 5,A
  CP $59
  POP HL
  RET
YES_NO:
  DEFM "Yes (Y)?"
FINDMS:
  LD HL,(GAME_BASE)
  CP (HL)
  JR NC,L7F08
  CP $81
  JR C,L7F08
  RES 7,A
  LD B,A
  LD DE,$0005
  LD HL,(OBJLOC)
L7EF8:
  ADD HL,DE
  DJNZ L7EF8
  LD A,(IY+$01)
  OR A
  RET NZ
  LD A,(HL)
  CP $FC
  RET NZ
  ADD HL,DE
  CP $01
  RET
L7F08:
  XOR A
  RET
L7F0A:
  LD (COMP_PTR),HL
  XOR A
  LD (NIBBLE_TOGGLE),A
  LD (EXPAND_COUNT),A
  RET
DECOMP_GETCHR:
  PUSH DE
  PUSH BC
NEXT_SYMBOL:
  LD A,(EXPAND_COUNT)
  OR A
  JR NZ,EXPAND_CHAR
  CALL GET_NIBBLE
  BIT 3,A
  JR NZ,HANDLE_SPECIAL
  BIT 2,A
  JP NZ,DECOMP_LITERAL
  CALL GET_TOKEN6
  OR A
  JR Z,RETURN_CHAR
  CALL DICT_LOOKUP
EXPAND_CHAR:
  LD HL,(EXPAND_PTR)
  DEC A
  LD (EXPAND_COUNT),A
  LD A,(HL)
  INC HL
  LD (EXPAND_PTR),HL
RETURN_CHAR:
  LD HL,EXP_CHAR
  LD (HL),A
  LD A,(CAPITAL_FLG)
  OR A
  JR Z,EXIT_DECOMP
  RES 5,(HL)
  XOR A
  LD (CAPITAL_FLG),A
EXIT_DECOMP:
  POP BC
  POP DE
  RET

DICT_LOOKUP:
  LD HL,MAIN_DICT
DICT_FETCH:
  LD E,A
  LD D,$00
  ADD HL,DE
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD H,(HL)
  LD L,E
  LD A,(HL)
  INC HL
  LD (EXPAND_PTR),HL
  RET
GET_TOKEN6:
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD B,A
  CALL GET_NIBBLE
  OR B
  AND $3F
  RET
GET_NIBBLE:
  LD HL,(COMP_PTR)
  LD A,(NIBBLE_TOGGLE)
  CPL
  LD (NIBBLE_TOGGLE),A
  CP $FF
  JR Z,GET_HINIBBLE
  LD A,(HL)
  AND $0F
  INC HL
  LD (COMP_PTR),HL
  RET
GET_HINIBBLE:
  LD A,(HL)
  RRA
  RRA
  RRA
  RRA
  AND $0F
  RET
HANDLE_SPECIAL:
  AND $07
  CP $07
  JR Z,NEXT_SYMBOL
  CP $06
  JR NZ,L7F9D
SET_CAPITALISE:
  LD (CAPITAL_FLG),A
  JP NEXT_SYMBOL
L7F9D:
  CP $04
  JR C,SPECIAL_CHAR
  JR NZ,FETCH_LONG_TOKEN
FETCH_SHORT_TOKEN:
  CALL GET_NIBBLE
  LD HL,SHORT_DICT-2
  CALL DICT_FETCH
  JP EXPAND_CHAR
FETCH_LONG_TOKEN:
  CALL GET_NIBBLE
  RLA
  RLA
  RLA
  RLA
  LD B,A
  CALL GET_NIBBLE
  ADD A,B
  LD HL,LONG_DICT
  CALL DICT_FETCH
  JP EXPAND_CHAR
SPECIAL_CHAR:
  LD HL,SPECIAL_CHR
SPECIAL_FETCH:
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  JP RETURN_CHAR
DECOMP_LITERAL:
  CALL GET_TOKEN6
  CP $0A
  JR NC,L7FDB
  ADD A,$30
  JP RETURN_CHAR
L7FDB:
  CP $24
  JR NC,L7FE4
  ADD A,$57
  JP RETURN_CHAR
L7FE4:
  LD HL,SYMB_CHR
  SUB $24
  JR SPECIAL_FETCH

; Message at 7FEB
T_A:
  DEFB $02
  DEFM "a "

; Message at 7FEE
T_AT:
  DEFB $03
  DEFM "at "

; Message at 7FF2
T_BY:
  DEFB $03
  DEFM "by "

; Message at 7FF6
T_OUT:
  DEFB $03
  DEFM "out"

; Message at 7FFA
T_IN_:
  DEFB $03
  DEFM "in "

; Message at 7FFE
T_IS:
  DEFB $03
  DEFM "is "

; Message at 8002
T_IT:
  DEFB $03
  DEFM "it "

; Message at 8006
T_OF:
  DEFB $03
  DEFM "of "

; Message at 800A
T_TO:
  DEFB $03
  DEFM "to "

; Message at 800E
T_UP:
  DEFB $03
  DEFM "up "

; Message at 8012
T_AND:
  DEFB $04
  DEFM "and "

; Message at 8017
T_ARE:
  DEFB $04
  DEFM "are "

; Message at 801C
T_FLAMES:
  DEFB $06
  DEFM "flames"

; Message at 8023
T_EAST:
  DEFB $04
  DEFM "east"

; Message at 8028
T_ERN:
  DEFB $04
  DEFM "ern "

; Message at 802D
T_THE:
  DEFB $04
  DEFM "the "

; Message at 8032
T_WEST:
  DEFB $04
  DEFM "west"

; Message at 8037
T_HERE:
  DEFB $04
  DEFM "here"

; Message at 803C
T_WHICH:
  DEFB $05
  DEFM "which"

; Message at 8042
T_DOWN_SP:
  DEFB $05
  DEFM "down "

; Message at 8048
T_EXIT:
  DEFB $04
  DEFM "exit"

; Message at 804D
T_FROM_SP:
  DEFB $05
  DEFM "from "

; Message at 8053
T_ROOM:
  DEFB $04
  DEFM "room"

; Message at 8058
T_LAKE_SP:
  DEFB $05
  DEFM "lake "

; Message at 805E
T_AMP:
  DEFB $04
  DEFM "amp "

; Message at 8063
T_NORTH:
  DEFB $05
  DEFM "north"

; Message at 8069
T_AKE:
  DEFB $03
  DEFM "ake"

; Message at 806D
T_ARROW:
  DEFB $05
  DEFM "arrow"

; Message at 8073
T_OPEN:
  DEFB $04
  DEFM "open"

; Message at 8078
T_SOUTH:
  DEFB $05
  DEFM "south"

; Message at 807E
T_STAR:
  DEFB $04
  DEFM "star"

; Message at 8083
T_THAT_SP:
  DEFB $05
  DEFM "that "

; Message at 8089
T_WALL:
  DEFB $04
  DEFM "wall"

; Message at 808E
T_WITH_SP:
  DEFB $05
  DEFM "with "

; Message at 8094
T_RAMPART:
  DEFB $07
  DEFM "rampart"

; Message at 809C
T_FLOOR:
  DEFB $05
  DEFM "floor"

; Message at 80A2
T_LARGE_SP:
  DEFB $06
  DEFM "large "

; Message at 80A9
T_ING:
  DEFB $03
  DEFM "ing"

; Message at 80AD
T_SMALL:
  DEFB $05
  DEFM "small"

; Message at 80B3
T_SWORD:
  DEFB $05
  DEFM "sword"

; Message at 80B9
T_THERE_SP:
  DEFB $06
  DEFM "there "

; Message at 80C0
T_LOC:
  DEFB $04
  DEFM "#loc"

; Message at 80C5
T_ED:
  DEFB $03
  DEFM "ed "

; Message at 80C9
T_CASTLE:
  DEFB $06
  DEFM "castle"

; Message at 80D0
T_CORNER:
  DEFB $06
  DEFM "corner"

; Message at 80D7
T_DRAGON:
  DEFB $06
  DEFM "dragon"

; Message at 80DE
T_MIDDLE_SP:
  DEFB $07
  DEFM "middle "

; Message at 80E6
T_CHECKERBOARD:
  DEFB $0D
  DEFM "checkerboard "

; Message at 80F4
T_LY:
  DEFB $03
  DEFM "ly "

; Message at 80F8
T_PASSAGE:
  DEFB $07
  DEFM "passage"

; Message at 8100
T_CORRIDOR:
  DEFB $08
  DEFM "corridor"

; Message at 8109
T_CAN:
  DEFB $03
  DEFM "can"

; Message at 810D
T_WOODLAND:
  DEFB $08
  DEFM "woodland"

; Message at 8116
T_SAIL:
  DEFB $04
  DEFM "sail"

; Message at 811B
T_YOU_ARE:
  DEFB $08
  DEFM "you are "

; Message at 8124
T_THIS_IS:
  DEFB $08
  DEFM "this is "

; Message at 812D
T_ING_SP:
  DEFB $04
  DEFM "ing "

; Message at 8132
T_YOU:
  DEFB $03
  DEFM "you"

; Message at 8136
T_ENTRANCE:
  DEFB $08
  DEFM "entrance"

; Message at 813F
T_JUNCTION:
  DEFB $08
  DEFM "junction"

; Message at 8148
T_COURTYARD:
  DEFB $09
  DEFM "courtyard"

; Message at 8152
T_SPACE:
  DEFB $01
  DEFM " "

; Message at 8154
T_TOWER:
  DEFB $05
  DEFM "tower"
  DEFB $FD

; Message at 815B
T_HAS:
  DEFB $03
  DEFM "has"

; Message at 815F
T_NOT:
  DEFB $03
  DEFM "not"

; Message at 8163
T_ABOVE:
  DEFB $05
  DEFM "above"

; Message at 8169
T_ROUND:
  DEFB $05
  DEFM "round"

; Message at 816F
T_ENTER:
  DEFB $05
  DEFM "enter"

; Message at 8175
T_APPEAR:
  DEFB $06
  DEFM "appear"

; Message at 817C
T_OVER_SP:
  DEFB $05
  DEFM "over "

; Message at 8182
T_WARD:
  DEFB $04
  DEFM "ward"

; Message at 8187
T_COMPLEX:
  DEFB $07
  DEFM "complex"

; Message at 818F
T_THROUGH:
  DEFB $07
  DEFM "through"

; Message at 8197
T_DOOR:
  DEFB $04
  DEFM "door"

; Message at 819C
T_ITS:
  DEFB $05
  DEFM "it's "

; Message at 81A2
T_END:
  DEFB $03
  DEFM "end"

; Message at 81A6
T_LAKE:
  DEFB $04
  DEFM "lake"

; Message at 81AB
T_CLOSE:
  DEFB $05
  DEFM "close"
  DEFB $FE

; Message at 81B2
T_SQUARE_SP:
  DEFB $07
  DEFM "square "

; Message at 81BA
T_WATER_SP:
  DEFB $06
  DEFM "water "

; Message at 81C1
T_STONE:
  DEFB $05
  DEFM "stone"

; Message at 81C7
T_TUNNEL:
  DEFB $06
  DEFM "tunnel"

; Message at 81CE
T_VERY_SP:
  DEFB $05
  DEFM "very "

; Message at 81D4
T_BUT_SP:
  DEFB $04
  DEFM "but "

; Message at 81D9
T_LAND:
  DEFB $04
  DEFM "land"

; Message at 81DE
T_LEAD:
  DEFB $04
  DEFM "lead"

; Message at 81E3
T_LOW:
  DEFB $03
  DEFM "low"

; Message at 81E7
T_IGHT:
  DEFB $04
  DEFM "ight"

; Message at 81EC
T_SIDE:
  DEFB $04
  DEFM "side"

; Message at 81F1
T_LOCK:
  DEFB $04
  DEFM "lock"

; Message at 81F6
T_WAY:
  DEFB $03
  DEFM "way"

; Message at 81FA
T_SECRET_SP:
  DEFB $07
  DEFM "secret "

; Message at 8202
T_HOLE:
  DEFB $04
  DEFM "hole"

; Message at 8207
T_STAIR:
  DEFB $05
  DEFM "stair"

; Message at 820D
T_DEAD:
  DEFB $04
  DEFM "dead"

; Message at 8212
T_LONG:
  DEFB $04
  DEFM "long"

; Message at 8217
T_TALL:
  DEFB $04
  DEFM "tall"

; Message at 821C
T_VALLEY:
  DEFB $06
  DEFM "valley"

; Message at 8223
T_DUSTY:
  DEFB $05
  DEFM "dusty"

; Message at 8229
T_ROAD:
  DEFB $04
  DEFM "road"

; Message at 822E
T_FRONT:
  DEFB $05
  DEFM "front"

; Message at 8234
T_BEHIND:
  DEFB $06
  DEFM "behind"

; Message at 823B
T_WELL:
  DEFB $04
  DEFM "well"

; Message at 8240
T_BOTTOM:
  DEFB $06
  DEFM "bottom"

; Message at 8247
T_CAVE:
  DEFB $04
  DEFM "cave"

; Message at 824C
T_IRON:
  DEFB $04
  DEFM "iron"

; Message at 8251
T_HEXAGON:
  DEFB $07
  DEFM "hexagon"

; Message at 8259
T_EQUIPMENT:
  DEFB $09
  DEFM "equipment"

; Message at 8263
T_BUILD:
  DEFB $05
  DEFM "build"

; Message at 8269
T_WINDOW:
  DEFB $06
  DEFM "window"

; Message at 8270
T_ARMOURY:
  DEFB $07
  DEFM "armoury"

; Message at 8278
T_KITCHEN:
  DEFB $07
  DEFM "kitchen"

; Message at 8280
T_BLACK:
  DEFB $05
  DEFM "black"

; Message at 8286
T_MIRROR:
  DEFB $06
  DEFM "mirror"

; Message at 828D
T_SERVANT:
  DEFB $07
  DEFM "servant"

; Message at 8295
T_ROCK:
  DEFB $04
  DEFM "rock"

; Message at 829A
T_TIGHT:
  DEFB $05
  DEFM "tight"

; Message at 82A0
T_RUBBLE:
  DEFB $06
  DEFM "rubble"

; Message at 82A7
T_BRIDGE:
  DEFB $06
  DEFM "bridge"

; Message at 82AE
T_ISLAND:
  DEFB $06
  DEFM "island"

; Message at 82B5
T_INLET:
  DEFB $05
  DEFM "inlet"

; Message at 82BB
T_RIVER_SP:
  DEFB $06
  DEFM "river "

; Message at 82C2
T_FORK:
  DEFB $04
  DEFM "fork"

; Message at 82C7
T_BLOCK:
  DEFB $05
  DEFM "block"

; Message at 82CD
T_RIVER:
  DEFB $05
  DEFM "river"

; Message at 82D3
T_LIME:
  DEFB $04
  DEFM "lime"

; Message at 82D8
T_PENTACLE:
  DEFB $08
  DEFM "pentacle"

; Message at 82E1
T_CHAPEL:
  DEFB $06
  DEFM "chapel"

; Message at 82E8
T_THRONE:
  DEFB $06
  DEFM "throne"

; Message at 82EF
T_FISSURE:
  DEFB $07
  DEFM "fissure"

; Message at 82F7
T_LABORATORY:
  DEFB $0A
  DEFM "laboratory"

; Message at 8302
T_WARM:
  DEFB $04
  DEFM "warm"

; Message at 8307
T_CLEAR:
  DEFB $05
  DEFM "clear"

; Message at 830D
T_CHANDELIER:
  DEFB $0A
  DEFM "chandelier"

; Message at 8318
T_STILL:
  DEFB $05
  DEFM "still"

; Message at 831E
T_POOL:
  DEFB $04
  DEFM "pool"

; Message at 8323
T_HEAT:
  DEFB $04
  DEFM "heat"

; Message at 8328
T_SPLIT:
  DEFB $05
  DEFM "split"

; Message at 832E
T_PICTURE:
  DEFB $07
  DEFM "picture"

; Message at 8336
T_CREVICE:
  DEFB $07
  DEFM "crevice"

; Message at 833E
T_GALLERY:
  DEFB $07
  DEFM "gallery"

; Message at 8346
T_GARDEN:
  DEFB $06
  DEFM "garden"

; Message at 834D
T_OVER:
  DEFB $04
  DEFM "over"

; Message at 8352
T_FOREST:
  DEFB $06
  DEFM "forest"

; Message at 8359
T_TOUCH:
  DEFB $05
  DEFM "touch"

; Message at 835F
T_MACHINE:
  DEFB $07
  DEFM "machine"

; Message at 8367
T_COLD:
  DEFB $04
  DEFM "cold"

; Message at 836C
T_DRAW:
  DEFB $04
  DEFM "draw"

; Message at 8371
T_SHAPE:
  DEFB $05
  DEFM "shape"

; Message at 8377
T_READ:
  DEFB $04
  DEFM "read"

; Message at 837C
T_TRAP:
  DEFB $04
  DEFM "trap"

; Message at 8381
T_COME:
  DEFB $04
  DEFM "come"

; Message at 8386
T_HAVE:
  DEFB $04
  DEFM "have"

; Message at 838B
T_BUTTON:
  DEFB $06
  DEFM "button"

; Message at 8392
T_GIGANTIC:
  DEFB $09
  DEFM "gigantic "

; Message at 839C
T_UNDER:
  DEFB $05
  DEFM "under"

; Message at 83A2
T_LETTER:
  DEFB $06
  DEFM "letter"

; Message at 83A9
T_CRACK:
  DEFB $05
  DEFM "crack"

; Message at 83AF
T_CEIL:
  DEFB $04
  DEFM "ceil"

; Message at 83B4
T_IM_AFRAID:
  DEFB $0A
  DEFM "i'm afraid"

; Message at 83BF
T_GINGERBREAD:
  DEFB $0B
  DEFM "gingerbread"

; Message at 83CB
T_PORTCULLIS:
  DEFB $0A
  DEFM "portcullis"

; Message at 83D6
T_DYNAMITE:
  DEFB $08
  DEFM "dynamite"

; Message at 83DF
T_WHERE_SP:
  DEFB $06
  DEFM "where "

; Message at 83E6
T_NEXT_SP:
  DEFB $05
  DEFM "next "

; Message at 83EC
T_MACHINE2:
  DEFB $07
  DEFM "machine"

; Message at 83F4
T_DARK:
  DEFB $04
  DEFM "dark"

; Message at 83F9
T_DEBRIS:
  DEFB $06
  DEFM "debris"

; Message at 8400
T_STATUE:
  DEFB $06
  DEFM "statue"

; Message at 8407
T_PATH:
  DEFB $04
  DEFM "path"

; Message at 840C
T_THICK:
  DEFB $05
  DEFM "thick"

; Message at 8412
T_STONE2:
  DEFB $05
  DEFM "stone"

; Message at 8418
T_CROSS:
  DEFB $05
  DEFM "cross"

; Message at 841E
T_GLITTER:
  DEFB $07
  DEFM "glitter"

; Message at 8426
T_SOLID:
  DEFB $05
  DEFM "solid"

; Message at 842C
T_VERY:
  DEFB $04
  DEFM "very"

; Message at 8431
T_LOOK:
  DEFB $04
  DEFM "look"

; Message at 8436
T_BELOW:
  DEFB $05
  DEFM "below"

; Message at 843C
T_WHIRR:
  DEFB $05
  DEFM "whirr"

; Message at 8442
T_TOP_SP:
  DEFB $04
  DEFM "top "

; Message at 8447
T_ARCH:
  DEFB $04
  DEFM "arch"

; Message at 844C
T_COVE:
  DEFB $04
  DEFM "cove"

; Message at 8451
T_ON_SP:
  DEFB $03
  DEFM "on "

; Message at 8455
T_STAND:
  DEFB $05
  DEFM "stand"

; Message at 845B
T_JOIN:
  DEFB $04
  DEFM "join"

; Message at 8460
T_INTO:
  DEFB $04
  DEFM "into"

; Message at 8465
T_ALREADY:
  DEFB $07
  DEFM "already"

; Message at 846D
T_HEAVY:
  DEFB $05
  DEFM "heavy"

; Message at 8473
T_EXPLO:
  DEFB $05
  DEFM "explo"

; Message at 8479
T_RAIS:
  DEFB $04
  DEFM "rais"

; Message at 847E
T_SECTION:
  DEFB $07
  DEFM "section"

; Message at 8486
T_DESCEND:
  DEFB $07
  DEFM "descend"

; Message at 848E
T_MIDDLE:
  DEFB $06
  DEFM "middle"

; Message at 8495
T_WIND:
  DEFB $04
  DEFM "wind"

; Message at 849A
T_SOMEWHERE:
  DEFB $09
  DEFM "somewhere"

; Message at 84A4
T_WATER:
  DEFB $05
  DEFM "water"

; Message at 84AA
T_BANK_SP:
  DEFB $05
  DEFM "bank "

; Message at 84B0
T_SEE:
  DEFB $03
  DEFM "see"

; Message at 84B4
T_DWARF:
  DEFB $05
  DEFM "dwarf"

; Message at 84BA
T_FILLED:
  DEFB $06
  DEFM "filled"

; Message at 84C1
T_HEAR:
  DEFB $04
  DEFM "hear"

; Message at 84C6
T_LARGE:
  DEFB $05
  DEFM "large"

; Message at 84CC
T_MESSAGE:
  DEFB $07
  DEFM "message"

; Message at 84D4
T_STRONG_SP:
  DEFB $07
  DEFM "strong "

; Message at 84DC
T_ON:
  DEFB $02
  DEFM "on"

; Message at 84DF
T_DENSE:
  DEFB $05
  DEFM "dense"

; Message at 84E5
T_UP_SP:
  DEFB $03
  DEFM "up "

; Message at 84E9
T_ABLE:
  DEFB $04
  DEFM "able"

; Message at 84EE
T_FROM:
  DEFB $04
  DEFM "from"

; Message at 84F3
T_WINDOW2:
  DEFB $06
  DEFM "window"

; Message at 84FA
T_GOLD:
  DEFB $04
  DEFM "gold"

; Message at 84FF
T_HOLD:
  DEFB $04
  DEFM "hold"

; Message at 8504
T_LEAVE:
  DEFB $05
  DEFM "leave"

; Message at 850A
T_OFF_SP:
  DEFB $04
  DEFM "off "

; Message at 850F
T_GREAT:
  DEFB $05
  DEFM "great"

; Message at 8515
T_WITH:
  DEFB $04
  DEFM "with"

; Message at 851A
T_STEPS:
  DEFB $05
  DEFM "steps"

; Message at 8520
T_SPACE2:
  DEFB $01
  DEFM " "

; Message at 8522
T_GLORIOUS:
  DEFB $08
  DEFM "glorious"

; Message at 852B
T_HANG:
  DEFB $04
  DEFM "hang"

; Message at 8530
T_RAPID:
  DEFB $05
  DEFM "rapid"

; Message at 8536
T_ONLY_SP:
  DEFB $05
  DEFM "only "

; Message at 853C
T_LESS:
  DEFB $04
  DEFM "less"

; Message at 8541
T_ILL:
  DEFB $03
  DEFM "ill"

; Message at 8545
T_IT_SP:
  DEFB $03
  DEFM "it "

; Message at 8549
T_AFTER:
  DEFB $05
  DEFM "after"

; Message at 854F
T_SCATTERED:
  DEFB $09
  DEFM "scattered"

; Message at 8559
T_FOLLOW:
  DEFB $06
  DEFM "follow"

; Message at 8560
T_GLOOMY:
  DEFB $06
  DEFM "gloomy"

; Message at 8567
T_BRINK:
  DEFB $05
  DEFM "brink"

; Message at 856D
T_PIT:
  DEFB $03
  DEFM "pit"

; Message at 8571
T_EACH:
  DEFB $04
  DEFM "each"

; Message at 8576
T_CENTRE:
  DEFB $06
  DEFM "centre"

; Message at 857D
T_AN:
  DEFB $02
  DEFM "an"

; Message at 8580
T_THER:
  DEFB $04
  DEFM "ther"

; Message at 8585
T_WHOSE:
  DEFB $05
  DEFM "whose"

; Message at 858B
T_PRESEN:
  DEFB $06
  DEFM "presen"

; Message at 8592
T_LEAVE2:
  DEFB $05
  DEFM "leave"

; Message at 8598
T_SHORE:
  DEFB $05
  DEFM "shore"

; Message at 859E
T_COULD:
  DEFB $05
  DEFM "could"

; Message at 85A4
T_PROBABL:
  DEFB $07
  DEFM "probabl"

; Message at 85AC
T_CRAWL:
  DEFB $05
  DEFM "crawl"

; Message at 85B2
T_DIRECTION:
  DEFB $09
  DEFM "direction"

; Message at 85BC
T_ALL:
  DEFB $03
  DEFM "all"

; Message at 85C0
T_POSSIBL:
  DEFB $07
  DEFM "possibl"

; Message at 85C8
T_CELL:
  DEFB $04
  DEFM "cell"

; Message at 85CD
T_PROTECT:
  DEFB $07
  DEFM "protect"

; Message at 85D5
T_DOWN:
  DEFB $04
  DEFM "down"

; Message at 85DA
T_BEEN:
  DEFB $04
  DEFM "been"

; Message at 85DF
T_HAPPEN:
  DEFB $06
  DEFM "happen"

; Message at 85E6
T_TION:
  DEFB $04
  DEFM "tion"

; Message at 85EB
T_WORK:
  DEFB $04
  DEFM "work"

; Message at 85F0
T_IN:
  DEFB $02
  DEFM "in"

; Message at 85F3
T_ROPE:
  DEFB $04
  DEFM "rope"

; Message at 85F8
T_LADDER:
  DEFB $06
  DEFM "ladder"

; Message at 85FF
T_WOOD:
  DEFB $04
  DEFM "wood"

; Message at 8604
T_BOAT:
  DEFB $04
  DEFM "boat"

; Message at 8609
T_SOUND:
  DEFB $05
  DEFM "sound"

; Message at 860F
T_RUNS:
  DEFB $04
  DEFM "runs"

; Message at 8614
T_HEAD:
  DEFB $04
  DEFM "head"

; Message at 8619
T_GRAT:
  DEFB $04
  DEFM "grat"

; Message at 861E
T_SMELL:
  DEFB $05
  DEFM "smell"

; Message at 8624
T_TREES:
  DEFB $05
  DEFM "trees"

; Message at 862A
T_TROLL:
  DEFB $05
  DEFM "troll"

; Message at 8630
T_SHARP:
  DEFB $05
  DEFM "sharp"

; Message at 8636
T_HISS:
  DEFB $04
  DEFM "hiss"

; Message at 863B
T_EATH:
  DEFB $04
  DEFM "eath"

; Message at 8640
T_TH:
  DEFB $02
  DEFM "th"

; Message at 8643
T_EMPTY:
  DEFB $05
  DEFM "empty"

; Message at 8649
T_BACK:
  DEFB $04
  DEFM "back"

; Message at 864E
T_LAMP:
  DEFB $04
  DEFM "lamp"

; Message at 8653
T_LIKE:
  DEFB $04
  DEFM "like"

; Message at 8658
T_FIRE:
  DEFB $04
  DEFM "fire"

; Message at 865D
T_DUEL:
  DEFB $04
  DEFM "duel"

; Message at 8662
T_CASE:
  DEFB $04
  DEFM "case"

; Message at 8667
T_BED:
  DEFB $03
  DEFM "bed"

; Message at 866B
T_TEMPLE:
  DEFB $06
  DEFM "temple"

; Message at 8672
T_ENOUGH:
  DEFB $06
  DEFM "enough"

; Message at 8679
T_JUMP:
  DEFB $04
  DEFM "jump"

; Message at 867E
T_FOR:
  DEFB $03
  DEFM "for"

; Message at 8682
T_WHIL:
  DEFB $04
  DEFM "whil"

; Message at 8687
T_HAND:
  DEFB $04
  DEFM "hand"

; Message at 868C
T_CARRY:
  DEFB $05
  DEFM "carry"

; Message at 8692
T_ALTHOUGH:
  DEFB $08
  DEFM "although"

; Message at 869B
T_TIME:
  DEFB $04
  DEFM "time"

; Message at 86A0
T_CREAK:
  DEFB $05
  DEFM "creak"

; Message at 86A6
T_KNIFE:
  DEFB $05
  DEFM "knife"

; Message at 86AC
T_GODDESS:
  DEFB $07
  DEFM "goddess"

; Message at 86B4
T_LOAD:
  DEFB $04
  DEFM "load"

; Message at 86B9
T_SLIDE:
  DEFB $05
  DEFM "slide"

; Message at 86BF
T_FIND:
  DEFB $04
  DEFM "find"

; Message at 86C4
T_ATTACK:
  DEFB $06
  DEFM "attack"

; Message at 86CB
T_HYDRA:
  DEFB $05
  DEFM "hydra"

; Message at 86D1
T_SOME:
  DEFB $04
  DEFM "some"

; Message at 86D6
T_SORRY:
  DEFB $05
  DEFM "sorry"

; Message at 86DC
T_DONT:
  DEFB $05
  DEFM "don't"

; Message at 86E2
T_WHEEL:
  DEFB $05
  DEFM "wheel"

; Message at 86E8
T_THAT:
  DEFB $04
  DEFM "that"

; Message at 86ED
T_SEVERAL:
  DEFB $07
  DEFM "several"

; Message at 86F5
T_OULD:
  DEFB $04
  DEFM "ould"

; Message at 86FA
T_PRESS:
  DEFB $05
  DEFM "press"

; Message at 8700
T_STEEP:
  DEFB $05
  DEFM "steep"

; Message at 8706
T_VISIBLE:
  DEFB $07
  DEFM "visible"

; Message at 870E
T_SURFACE:
  DEFB $07
  DEFM "surface"

; Message at 8716
T_WRITTEN_SP:
  DEFB $08
  DEFM "written "

; Message at 871F
T_SLOPE:
  DEFB $05
  DEFM "slope"

; Message at 8725
T_HUGE:
  DEFB $04
  DEFM "huge"

; Message at 872A
T_CONT:
  DEFB $04
  DEFM "cont"

; Message at 872F
T_DWARVES:
  DEFB $07
  DEFM "dwarves"

; Message at 8737
T_SMOOTH:
  DEFB $06
  DEFM "smooth"

; Message at 873E
T_SHAFT:
  DEFB $05
  DEFM "shaft"

; Message at 8744
T_COTTAGE:
  DEFB $07
  DEFM "cottage"

; Message at 874C
T_BASE:
  DEFB $04
  DEFM "base"

; Message at 8751
T_BETWEEN:
  DEFB $07
  DEFM "between"

; Message at 8759
T_SEEM:
  DEFB $04
  DEFM "seem"

; Message at 875E
T_INTENSE:
  DEFB $07
  DEFM "intense"

; Message at 8766
T_REVEAL:
  DEFB $06
  DEFM "reveal"

; Message at 876D
T_CLIMB:
  DEFB $05
  DEFM "climb"

; Message at 8773
T_EXPLODE:
  DEFB $07
  DEFM "explode"

; Message at 877B
T_THEN:
  DEFB $04
  DEFM "then"

; Message at 8780
T_JUST:
  DEFB $04
  DEFM "just"

; Message at 8785
T_OBJECT:
  DEFB $06
  DEFM "object"

; Message at 878C
T_PART:
  DEFB $04
  DEFM "part"

; Message at 8791
T_HOW:
  DEFB $03
  DEFM "how"

; Message at 8795
T_EAGLE:
  DEFB $05
  DEFM "eagle"

; Message at 879B
T_LIQUID:
  DEFB $06
  DEFM "liquid"

; Message at 87A2
T_TOO:
  DEFB $03
  DEFM "too"

; Message at 87A6
T_OUGHT:
  DEFB $05
  DEFM "ought"

; Message at 87AC
T_STRETCH:
  DEFB $07
  DEFM "stretch"

; Message at 87B4
T_ATTEMPT:
  DEFB $07
  DEFM "attempt"

; Message at 87BC
T_EN:
  DEFB $02
  DEFM "en"

; Message at 87BF
T_LEDGE:
  DEFB $05
  DEFM "ledge"

; Message at 87C5
T_CURIO:
  DEFB $07
  DEFM "curio"
  DEFW L7375
SHORT_DICT:
  DEFW T_HAS
  DEFW T_NOT
  DEFW T_ABOVE
  DEFW T_ROUND
  DEFW T_ENTER
  DEFW T_APPEAR
  DEFW T_OVER_SP
  DEFW T_WARD
  DEFW T_COMPLEX
  DEFW T_THROUGH
  DEFW T_DOOR
  DEFW T_ITS
  DEFW T_END
  DEFW T_LAKE
MAIN_DICT:
  DEFW T_CLOSE
  DEFW T_A
  DEFW T_AT
  DEFW T_BY
  DEFW T_OUT
  DEFW T_IN_
  DEFW T_IS
  DEFW T_IT
  DEFW T_OF
  DEFW T_TO
  DEFW T_UP
  DEFW T_AND
  DEFW T_ARE
  DEFW T_FLAMES
  DEFW T_EAST
  DEFW T_ERN
  DEFW T_THE
  DEFW T_WEST
  DEFW T_HERE
  DEFW T_WHICH
  DEFW T_DOWN_SP
  DEFW T_EXIT
  DEFW T_FROM_SP
  DEFW T_ROOM
  DEFW T_LAKE_SP
  DEFW T_AMP
  DEFW T_NORTH
  DEFW T_AKE
  DEFW T_ARROW
  DEFW T_OPEN
  DEFW T_SOUTH
  DEFW T_STAR
  DEFW T_THAT_SP
  DEFW T_WALL
  DEFW T_WITH_SP
  DEFW T_RAMPART
  DEFW T_FLOOR
  DEFW T_LARGE_SP
  DEFW T_ING
  DEFW T_SMALL
  DEFW T_SWORD
  DEFW T_THERE_SP
  DEFW T_LOC
  DEFW T_ED
  DEFW T_CASTLE
  DEFW T_CORNER
  DEFW T_DRAGON
  DEFW T_MIDDLE_SP
  DEFW T_CHECKERBOARD
  DEFW T_LY
  DEFW T_PASSAGE
  DEFW T_CORRIDOR
  DEFW T_CAN
  DEFW T_WOODLAND
  DEFW T_SAIL
  DEFW T_YOU_ARE
  DEFW T_THIS_IS
  DEFW T_ING_SP
  DEFW T_YOU
  DEFW T_ENTRANCE
  DEFW T_JUNCTION
  DEFW T_COURTYARD
  DEFW T_SPACE
LONG_DICT:
  DEFW T_TOWER
  DEFW T_SQUARE_SP
  DEFW T_WATER_SP
  DEFW T_STONE
  DEFW T_TUNNEL
  DEFW T_VERY_SP
  DEFW T_BUT_SP
  DEFW T_LAND
  DEFW T_LEAD
  DEFW T_LOW
  DEFW T_IGHT
  DEFW T_SIDE
  DEFW T_LOCK
  DEFW T_WAY
  DEFW T_SECRET_SP
  DEFW T_HOLE
  DEFW T_STAIR
  DEFW T_DEAD
  DEFW T_LONG
  DEFW T_TALL
  DEFW T_VALLEY
  DEFW T_DUSTY
  DEFW T_ROAD
  DEFW T_FRONT
  DEFW T_BEHIND
  DEFW T_WELL
  DEFW T_BOTTOM
  DEFW T_CAVE
  DEFW T_IRON
  DEFW T_HEXAGON
  DEFW T_EQUIPMENT
  DEFW T_BUILD
  DEFW T_WINDOW
  DEFW T_ARMOURY
  DEFW T_KITCHEN
  DEFW T_BLACK
  DEFW T_MIRROR
  DEFW T_SERVANT
  DEFW T_ROCK
  DEFW T_TIGHT
  DEFW T_RUBBLE
  DEFW T_BRIDGE
  DEFW T_ISLAND
  DEFW T_INLET
  DEFW T_RIVER_SP
  DEFW T_FORK
  DEFW T_BLOCK
  DEFW T_RIVER
  DEFW T_LIME
  DEFW T_PENTACLE
  DEFW T_CHAPEL
  DEFW T_THRONE
  DEFW T_FISSURE
  DEFW T_LABORATORY
  DEFW T_WARM
  DEFW T_CLEAR
  DEFW T_CHANDELIER
  DEFW T_STILL
  DEFW T_POOL
  DEFW T_HEAT
  DEFW T_SPLIT
  DEFW T_PICTURE
  DEFW T_CREVICE
  DEFW T_GALLERY
  DEFW T_GARDEN
  DEFW T_OVER
  DEFW T_FOREST
  DEFW T_TOUCH
  DEFW T_MACHINE
  DEFW T_COLD
  DEFW T_DRAW
  DEFW T_SHAPE
  DEFW T_READ
  DEFW T_TRAP
  DEFW T_COME
  DEFW T_HAVE
  DEFW T_BUTTON
  DEFW T_GIGANTIC
  DEFW T_UNDER
  DEFW T_LETTER
  DEFW T_CRACK
  DEFW T_CEIL
  DEFW T_IM_AFRAID
  DEFW T_GINGERBREAD
  DEFW T_PORTCULLIS
  DEFW T_DYNAMITE
  DEFW T_WHERE_SP
  DEFW T_NEXT_SP
  DEFW T_MACHINE2
  DEFW T_DARK
  DEFW T_DEBRIS
  DEFW T_STATUE
  DEFW T_PATH
  DEFW T_THICK
  DEFW T_STONE2
  DEFW T_CROSS
  DEFW T_GLITTER
  DEFW T_SOLID
  DEFW T_VERY
  DEFW T_LOOK
  DEFW T_BELOW
  DEFW T_WHIRR
  DEFW T_TOP_SP
  DEFW T_ARCH
  DEFW T_COVE
  DEFW T_ON_SP
  DEFW T_STAND
  DEFW T_JOIN
  DEFW T_INTO
  DEFW T_ALREADY
  DEFW T_HEAVY
  DEFW T_EXPLO
  DEFW T_RAIS
  DEFW T_SECTION
  DEFW T_DESCEND
  DEFW T_MIDDLE
  DEFW T_WIND
  DEFW T_SOMEWHERE
  DEFW T_WATER
  DEFW T_BANK_SP
  DEFW T_SEE
  DEFW T_DWARF
  DEFW T_FILLED
  DEFW T_HEAR
  DEFW T_LARGE
  DEFW T_MESSAGE
  DEFW T_STRONG_SP
  DEFW T_ON
  DEFW T_DENSE
  DEFW T_UP_SP
  DEFW T_ABLE
  DEFW T_FROM
  DEFW T_WINDOW2
  DEFW T_GOLD
  DEFW T_HOLD
  DEFW T_LEAVE
  DEFW T_OFF_SP
  DEFW T_GREAT
  DEFW T_WITH
  DEFW T_STEPS
  DEFW T_SPACE2
  DEFW T_GLORIOUS
  DEFW T_HANG
  DEFW T_RAPID
  DEFW T_ONLY_SP
  DEFW T_LESS
  DEFW T_ILL
  DEFW T_IT_SP
  DEFW T_AFTER
  DEFW T_SCATTERED
  DEFW T_FOLLOW
  DEFW T_GLOOMY
  DEFW T_BRINK
  DEFW T_PIT
  DEFW T_EACH
  DEFW T_CENTRE
  DEFW T_AN
  DEFW T_THER
  DEFW T_WHOSE
  DEFW T_PRESEN
  DEFW T_LEAVE2
  DEFW T_SHORE
  DEFW T_COULD
  DEFW T_PROBABL
  DEFW T_CRAWL
  DEFW T_DIRECTION
  DEFW T_ALL
  DEFW T_POSSIBL
  DEFW T_CELL
  DEFW T_PROTECT
  DEFW T_DOWN
  DEFW T_BEEN
  DEFW T_HAPPEN
  DEFW T_TION
  DEFW T_WORK
  DEFW T_IN
  DEFW T_ROPE
  DEFW T_LADDER
  DEFW T_WOOD
  DEFW T_BOAT
  DEFW T_SOUND
  DEFW T_RUNS
  DEFW T_HEAD
  DEFW T_GRAT
  DEFW T_SMELL
  DEFW T_TREES
  DEFW T_TROLL
  DEFW T_SHARP
  DEFW T_HISS
  DEFW T_EATH
  DEFW T_TH
  DEFW T_EMPTY
  DEFW T_BACK
  DEFW T_LAMP
  DEFW T_LIKE
  DEFW T_FIRE
  DEFW T_DUEL
  DEFW T_CASE
  DEFW T_BED
  DEFW T_TEMPLE
  DEFW T_ENOUGH
  DEFW T_JUMP
  DEFW T_FOR
  DEFW T_WHIL
  DEFW T_HAND
  DEFW T_CARRY
  DEFW T_ALTHOUGH
  DEFW T_TIME
  DEFW T_CREAK
  DEFW T_KNIFE
  DEFW T_GODDESS
  DEFW T_LOAD
  DEFW T_SLIDE
  DEFW T_FIND
  DEFW T_ATTACK
  DEFW T_HYDRA
  DEFW T_SOME
  DEFW T_SORRY
  DEFW T_DONT
  DEFW T_WHEEL
  DEFW T_THAT
  DEFW T_SEVERAL
  DEFW T_OULD
  DEFW T_PRESS
  DEFW T_STEEP
  DEFW T_VISIBLE
  DEFW T_SURFACE
  DEFW T_WRITTEN_SP
  DEFW T_SLOPE
  DEFW T_HUGE
  DEFW T_CONT
  DEFW T_DWARVES
  DEFW T_SMOOTH
  DEFW T_SHAFT
  DEFW T_COTTAGE
  DEFW T_BASE
  DEFW T_BETWEEN
  DEFW T_SEEM
  DEFW T_INTENSE
  DEFW T_REVEAL
  DEFW T_CLIMB
  DEFW T_EXPLODE
  DEFW T_THEN
  DEFW T_JUST
  DEFW T_OBJECT
  DEFW T_PART
  DEFW T_HOW
  DEFW T_EAGLE
  DEFW T_LIQUID
  DEFW T_TOO
  DEFW T_OUGHT
  DEFW T_STRETCH
  DEFW T_ATTEMPT
  DEFW T_EN
  DEFW T_LEDGE
  DEFW T_CURIO
EXP_CHAR:
  DEFB $C2
COMP_PTR:
  DEFW $0000
NIBBLE_TOGGLE:
  DEFB $01
EXPAND_COUNT:
  DEFB $00
EXPAND_PTR:
  DEFW $0000
SPECIAL_CHR:
  DEFM " esa"
SYMB_CHR:
  DEFM ",%{}><\"/@:()'?;-#![].-#![]."

; 371 (spare bytes removed)

; Data block at 8C00
GAME_BASE:
  DEFW LIVE_GAME

; Data block at 8C02
OBJLOC:
  DEFW LOC
OBPROP:
  DEFW OBPROP_TAB
TAB1:
  DEFW TAB1_TAB
_MSG:
  DEFW _MSG_TAB
TABKEY1:
  DEFW TABKEY1_TAB
OBJDES:
  DEFW OBJDES_TAB
FLAG:
  DEFW FLAG_TAB
FL06:
  DEFW FL06_TAB
FL09:
  DEFW FL09_TAB
FL13:
  DEFW FL13_TAB
FL14:
  DEFW FL14_TAB
FL16:
  DEFW FL16_TAB
FL17:
  DEFW FL17_TAB
FL20:
  DEFW FL20_TAB
FL21:
  DEFW FL21_TAB
TABKEY2:
  DEFW TABKEY2_TAB
MSG:
  DEFW MSG_TAB
UMESS:
  DEFW UMESS_TAB
LOC:
  DEFW LOC_TAB
TABKEY:
  DEFW TABKEY_TAB

LIVE_GAME:
  DEFB $B7,$FC,$01,$00,$00,$00,$36,$02
  DEFB $00,$00,$00,$AD,$C2,$00,$00,$00
  DEFB $FC,$C1,$00,$00,$00,$0B,$09,$7D
  DEFB $00,$00,$11,$0D,$00,$00,$00,$14
  DEFB $0A,$7E,$00,$00,$82,$0E,$84,$00
  DEFB $00,$36,$11,$00,$00,$00,$43,$22
  DEFB $00,$00,$00,$FC,$22,$85,$00,$00
  DEFB $48,$23,$83,$00,$00,$32,$31,$00
  DEFB $00,$00,$A6,$33,$00,$00,$00,$6A
  DEFB $2B,$00,$00,$00,$FC,$2C,$00,$00
  DEFB $00,$70,$2A,$00,$00,$00,$76,$29
  DEFB $00,$05,$00,$6E,$38,$00,$00,$00
  DEFB $FC,$39,$00,$00,$00,$FF,$01,$00
  DEFB $00,$00,$FC,$01,$00,$00,$00,$FF
  DEFB $47,$00,$00,$00,$FC,$48,$00,$00
  DEFB $00,$28,$54,$00,$00,$00,$FC,$55
  DEFB $00,$00,$00,$FF,$9E,$00,$03,$00
  DEFB $FF,$01,$87,$00,$00,$FF,$71,$88
  DEFB $00,$00,$FF,$9A,$00,$00,$00,$8A
  DEFB $9D,$00,$00,$00,$B4,$A8,$A9,$00
  DEFB $00,$81,$B3,$B4,$00,$00,$01,$03
  DEFB $7C,$03,$04,$FF,$0C,$00,$03,$04
  DEFB $90,$12,$00,$05,$04,$16,$13,$00
  DEFB $03,$04,$FF,$14,$7F,$03,$04,$2E
  DEFB $17,$80,$03,$04,$6C,$24,$00,$03
  DEFB $04,$FC,$21,$00,$00,$04,$38,$20
  DEFB $81,$05,$00,$08,$30,$00,$03,$04
  DEFB $6C,$32,$00,$03,$04,$FC,$34,$00
  DEFB $03,$04,$8A,$4B,$00,$00,$00,$7B
  DEFB $41,$00,$05,$04,$64,$43,$00,$03
  DEFB $04,$87,$49,$00,$05,$04,$9B,$59
  DEFB $00,$03,$04,$A3,$62,$86,$03,$04
  DEFB $AF,$9C,$00,$03,$04,$C7,$C3,$C4
  DEFB $03,$04,$AB,$CD,$00,$03,$04,$00
  DEFB $00


FLAG_TAB:
  DEFB $00,$01,$00,$08,$00,$00
FL06_TAB:
  DEFB $00,$00,$00
FL09_TAB:
  DEFB $00,$00,$81,$00
FL13_TAB:
  DEFB $0A
FL14_TAB:
  DEFB $0D,$00
FL16_TAB:
  DEFB $00
FL17_TAB:
  DEFB $01,$00,$00
FL20_TAB:
  DEFB $01
FL21_TAB:
  DEFB $00,$00,$00,$01,$00,$01,$02,$00
  DEFB $00,$00,$00,$01,$00,$01,$00,$00
  DEFB $00,$00,$00,$01,$01,$00,$01,$00
  DEFB $00,$00,$00,$01,$01,$05,$05,$00
  DEFB $01,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$01,$00,$00,$01,$00,$00,$00
  DEFB $00,$00,$00,$01,$00,$01,$01,$00
  DEFB $01,$00,$00,$00,$00,$00,$00,$06
  DEFB $00,$00,$00,$05,$06,$07,$04,$04
  DEFB $02,$03,$02,$04,$02,$02,$05,$02
  DEFB $03,$03,$0A,$04,$04,$03,$03,$04
  DEFB $02,$08,$04,$00,$00
  
OBPROP_TAB:
  DEFB $00,$85,$25,$26,$0E,$60,$32,$11
  DEFB $00,$8F,$60,$0E,$60,$32,$00,$90
  DEFB $0E,$60,$32,$00,$93,$26,$0E,$60
  DEFB $60,$32,$00,$94,$0E,$25,$60,$32
  DEFB $00,$95,$26,$0E,$60,$32,$00,$9C
  DEFB $0E,$60,$11,$32,$00,$9D,$21,$11
  DEFB $0E,$60,$32,$00,$A1,$0E,$60,$32
  DEFB $26,$00,$83,$0E,$60,$32,$00,$84
  DEFB $0E,$32,$60,$00,$00,$00

TAB1_TAB:
  DEFB $10,$FF,$FD,$1C,$58,$0D,$0D,$FF
  DEFB $3F,$00,$FD,$05,$6E,$83,$0D,$FF
  DEFB $41,$00,$FD,$84,$FF,$42,$00,$FD
  DEFB $87,$FF,$43,$00,$FD,$88,$FF,$40
  DEFB $00,$FD,$05,$6E,$89,$FF,$FF,$FF
  DEFB $FD,$08,$11,$00,$FE,$08,$81,$FD
  DEFB $08,$11,$01,$FE,$15,$0A,$28,$03
  DEFB $81,$12,$3E,$00,$FD,$05,$6B,$15
  DEFB $3E,$FE,$12,$0A,$00,$03,$81,$FD
  DEFB $08,$4C,$01,$05,$92,$FE,$12,$0A
  DEFB $00,$10,$81,$FC,$FD,$0A,$81,$08
  DEFB $11,$01,$08,$2B,$01,$FE,$1C,$0E
  DEFB $12,$10,$00,$11,$82,$13,$40,$00
  DEFB $FD,$05,$79,$19,$01,$05,$66,$0E
  DEFB $0C,$15,$40,$10,$FE,$1C,$0E,$12
  DEFB $10,$00,$12,$40,$00,$FD,$05,$78
  DEFB $0E,$40,$FE,$13,$10,$00,$FD,$08
  DEFB $40,$00,$FF,$15,$09,$FD,$80,$11
  DEFB $FF,$13,$0A,$FD,$80,$12,$FF,$2F
  DEFB $1B,$FD,$80,$1B,$FF,$13,$1B,$17
  DEFB $81,$FD,$80,$1B,$FF,$2F,$1A,$FD
  DEFB $80,$1A,$FF,$11,$1A,$FD,$80,$12
  DEFB $FF,$13,$1B,$FD,$80,$18,$FF,$3C
  DEFB $3E,$FD,$80,$3C,$FF,$34,$1B,$FD
  DEFB $80,$34,$FF,$12,$81,$FE,$95,$81
  DEFB $04,$82,$13,$3D,$00,$02,$43,$FD
  DEFB $14,$82,$05,$63,$10,$FF,$95,$FF
  DEFB $FE,$12,$FF,$1E,$81,$0B,$00,$FD
  DEFB $82,$00,$0B,$10,$FF,$12,$FF,$FE
  DEFB $14,$FF,$1F,$81,$FD,$06,$23,$10
  DEFB $FE,$0B,$00,$FD,$06,$23,$10,$FF
  DEFB $14,$FF,$1E,$81,$0B,$00,$FD,$82
  DEFB $00,$0B,$10,$FF,$11,$4D,$FE,$25
  DEFB $4D,$FE,$09,$FF,$01,$29,$12,$27
  DEFB $00,$FD,$06,$32,$10,$FE,$01,$29
  DEFB $FD,$0B,$86,$FF,$2D,$00,$01,$29
  DEFB $12,$27,$00,$FD,$06,$32,$10,$FE
  DEFB $01,$86,$FD,$0B,$87,$FF,$11,$5F
  DEFB $01,$36,$FD,$06,$36,$10,$FF,$11
  DEFB $4F,$01,$A9,$FD,$06,$35,$10,$FF
  DEFB $11,$4E,$01,$85,$FD,$06,$35,$10
  DEFB $FE,$01,$AB,$FD,$06,$2E,$10,$FF
  DEFB $11,$5C,$01,$8A,$FD,$06,$2B,$10
  DEFB $FF,$11,$47,$1D,$2E,$34,$FD,$06
  DEFB $35,$10,$FF,$11,$9D,$1D,$38,$0E
  DEFB $FD,$06,$36,$10,$FE,$01,$76,$FD
  DEFB $06,$35,$10,$FE,$01,$0E,$FD,$06
  DEFB $38,$10,$FF,$11,$9C,$01,$6C,$FD
  DEFB $06,$35,$10,$FF,$11,$20,$01,$77
  DEFB $FD,$06,$35,$10,$FF,$11,$46,$1D
  DEFB $15,$16,$FD,$06,$31,$10,$FF,$11
  DEFB $4C,$1D,$27,$19,$FD,$06,$31,$10
  DEFB $FF,$11,$55,$01,$85,$FD,$06,$38
  DEFB $10,$FF,$11,$51,$1D,$34,$88,$30
  DEFB $FD,$06,$36,$10,$FF,$34,$51,$1D
  DEFB $34,$88,$30,$FD,$06,$2F,$10,$FF
  DEFB $17,$88,$04,$88,$FD,$0C,$FF,$11
  DEFB $8C,$FE,$26,$8C,$08,$8C,$01,$8B
  DEFB $FD,$05,$4E,$10,$FF,$11,$69,$01
  DEFB $8B,$FD,$05,$A1,$10,$FF,$11,$5E
  DEFB $07,$85,$FD,$06,$35,$10,$FF,$11
  DEFB $5B,$1D,$08,$09,$FD,$06,$31,$10
  DEFB $FF,$11,$FF,$1F,$81,$FD,$06,$2E
  DEFB $10,$FE,$1E,$81,$05,$00,$FD,$06
  DEFB $2A,$10,$FE,$1E,$81,$04,$00,$FD
  DEFB $06,$2C,$10,$FF,$60,$83,$07,$84
  DEFB $FD,$06,$2A,$10,$FE,$02,$AD,$FD
  DEFB $06,$24,$10,$FE,$09,$A9,$09,$A6
  DEFB $09,$A0,$FD,$06,$30,$10,$FE,$FD
  DEFB $05,$C5,$FE,$12,$47,$00,$FD,$05
  DEFB $66,$10,$FE,$FD,$1B,$6F,$0D,$15
  DEFB $48,$0A,$83,$10,$FF,$FF,$FF,$01
  DEFB $AD,$04,$9E,$FD,$19,$01,$05,$C8
  DEFB $14,$9E,$05,$66,$10,$FF,$0A,$00
  DEFB $01,$AC,$FD,$0B,$AD,$FF,$01,$00
  DEFB $01,$AD,$13,$56,$02,$07,$83,$FD
  DEFB $08,$49,$01,$05,$C9,$08,$56,$02
  DEFB $10,$FE,$01,$AD,$07,$83,$FD,$08
  DEFB $56,$00,$05,$C8,$05,$66,$10,$FE
  DEFB $01,$AD,$FD,$0B,$C6,$FF,$FF,$FF
  DEFB $01,$AD,$13,$56,$00,$11,$C8,$07
  DEFB $83,$FD,$08,$56,$00,$05,$C8,$05
  DEFB $66,$10,$FE,$01,$AD,$12,$56,$00
  DEFB $07,$83,$11,$B4,$FD,$08,$56,$01
  DEFB $08,$49,$00,$05,$C9,$FF,$95,$9E
  DEFB $FE,$12,$9E,$01,$AC,$FD,$14,$9E
  DEFB $05,$C6,$05,$C7,$15,$47,$10,$FE
  DEFB $01,$AC,$0F,$83,$AD,$FD,$12,$00
  DEFB $AD,$05,$C6,$10,$FF,$60,$8F,$04
  DEFB $A6,$07,$8F,$13,$23,$00,$FD,$0A
  DEFB $8F,$1B,$59,$0D,$06,$1D,$19,$01
  DEFB $05,$6C,$10,$FE,$07,$8F,$05,$A7
  DEFB $04,$A9,$FD,$08,$2A,$01,$0A,$8F
  DEFB $1B,$59,$0D,$05,$67,$19,$01,$05
  DEFB $72,$10,$FE,$07,$8F,$12,$23,$00
  DEFB $FD,$19,$01,$05,$3F,$05,$66,$10
  DEFB $FE,$03,$90,$FD,$06,$2A,$10,$FF
  DEFB $95,$91,$FE,$24,$91,$02,$6A,$04
  DEFB $91,$FD,$05,$3D,$10,$FE,$01,$6A
  DEFB $FD,$14,$91,$1B,$5A,$0D,$15,$23
  DEFB $05,$3D,$16,$10,$FF,$FF,$FF,$12
  DEFB $3C,$02,$12,$23,$00,$0A,$A7,$07
  DEFB $8F,$11,$C8,$FD,$08,$3C,$00,$05
  DEFB $3F,$0E,$0C,$19,$02,$05,$66,$10
  DEFB $FE,$12,$3C,$01,$12,$23,$00,$07
  DEFB $8F,$0A,$A7,$11,$C8,$FD,$05,$64
  DEFB $0E,$3C,$FE,$13,$23,$00,$07,$8F
  DEFB $11,$C8,$FD,$05,$3E,$15,$23,$FE
  DEFB $12,$3C,$00,$FD,$0E,$3C,$FF,$03
  DEFB $00,$01,$6A,$12,$14,$5E,$FD,$0B
  DEFB $5E,$FE,$01,$6A,$13,$2A,$00,$FD
  DEFB $05,$46,$10,$FE,$07,$90,$FD,$0B
  DEFB $5E,$FE,$12,$23,$00,$01,$6A,$FD
  DEFB $05,$46,$10,$FF,$04,$00,$01,$6A
  DEFB $12,$14,$71,$FD,$0B,$71,$FE,$01
  DEFB $6A,$13,$2A,$00,$FD,$05,$46,$10
  DEFB $FE,$07,$90,$FD,$0B,$71,$FE,$12
  DEFB $23,$00,$01,$6A,$FD,$05,$46,$10
  DEFB $FF,$FF,$FF,$13,$09,$00,$11,$28
  DEFB $FD,$08,$0E,$7F,$08,$09,$00,$08
  DEFB $53,$00,$05,$B8,$05,$66,$10,$FE
  DEFB $13,$09,$00,$01,$B1,$1C,$09,$FD
  DEFB $0B,$B1,$FE,$13,$09,$00,$FD,$05
  DEFB $AB,$0B,$B1,$FE,$13,$53,$00,$FD
  DEFB $15,$53,$05,$C0,$0B,$0F,$FF,$FF
  DEFB $00,$1C,$09,$01,$BC,$FD,$0B,$BC
  DEFB $FE,$1C,$09,$1D,$96,$97,$98,$99
  DEFB $9A,$9B,$9C,$9D,$9E,$9F,$A0,$A1
  DEFB $FD,$0B,$A2,$FE,$1C,$0B,$1D,$58
  DEFB $59,$FD,$0B,$5B,$FE,$1C,$0B,$1D
  DEFB $BE,$BF,$FD,$0B,$BE,$FE,$1C,$0B
  DEFB $1D,$C0,$C1,$FD,$0B,$BF,$FF,$FF
  DEFB $FF,$11,$82,$1C,$09,$1D,$74,$75
  DEFB $FD,$0B,$73,$FE,$1C,$09,$1D,$74
  DEFB $75,$FD,$0B,$74,$FE,$12,$08,$00
  DEFB $10,$9B,$FC,$0D,$9B,$FD,$0A,$9A
  DEFB $FF,$01,$00,$01,$B2,$12,$42,$00
  DEFB $FD,$0B,$B3,$FF,$FF,$00,$11,$64
  DEFB $1C,$09,$1D,$0F,$10,$7E,$7F,$A7
  DEFB $80,$B2,$FD,$0B,$0F,$FE,$11,$78
  DEFB $1C,$09,$1D,$0F,$10,$7E,$7F,$A7
  DEFB $80,$B2,$FD,$05,$77,$10,$FE,$1C
  DEFB $09,$1D,$0F,$10,$7E,$7F,$A7,$80
  DEFB $FD,$0B,$10,$FF,$09,$00,$FE,$25
  DEFB $00,$1D,$0F,$10,$7E,$7F,$A7,$80
  DEFB $B2,$FD,$05,$7A,$10,$FF,$3B,$00
  DEFB $FD,$1A,$06,$1A,$05,$05,$5C,$10
  DEFB $FF,$11,$81,$07,$81,$FD,$02,$81
  DEFB $15,$11,$0C,$FE,$07,$82,$FD,$02
  DEFB $82,$0C,$FF,$11,$FF,$12,$10,$00
  DEFB $FD,$06,$24,$10,$FF,$11,$9E,$12
  DEFB $39,$00,$1D,$B3,$B4,$FD,$08,$39
  DEFB $01,$13,$9E,$02,$9E,$0C,$FE,$1D
  DEFB $B3,$B4,$FD,$05,$05,$10,$FF,$32
  DEFB $9E,$04,$9E,$20,$B3,$B4,$FD,$05
  DEFB $A6,$12,$9E,$FC,$10,$FE,$1D,$B3
  DEFB $B4,$FD,$05,$A6,$12,$9E,$FC,$05
  DEFB $05,$10,$FF,$14,$9E,$FE,$95,$9E
  DEFB $07,$93,$04,$9E,$FD,$12,$9E,$FC
  DEFB $05,$A7,$10,$FF,$0E,$5F,$01,$36
  DEFB $FD,$06,$2D,$10,$FF,$0A,$00,$01
  DEFB $36,$12,$1C,$00,$FD,$06,$15,$10
  DEFB $FE,$01,$36,$FD,$0B,$37,$FF,$26
  DEFB $5F,$01,$36,$FD,$06,$1D,$15,$1C
  DEFB $1D,$10,$FF,$1B,$5F,$01,$36,$09
  DEFB $81,$FD,$06,$30,$10,$FE,$01,$36
  DEFB $FD,$06,$09,$10,$FF,$11,$B4,$0F
  DEFB $B4,$AF,$1D,$AF,$BA,$FD,$02,$B4
  DEFB $08,$41,$00,$0C,$FF,$12,$B4,$1D
  DEFB $AF,$BA,$FD,$08,$41,$01,$04,$B4
  DEFB $0C,$FF,$11,$B6,$07,$00,$FD,$02
  DEFB $B6,$08,$4D,$00,$0C,$FF,$11,$9A
  DEFB $01,$B0,$0A,$9F,$13,$18,$00,$FD
  DEFB $05,$9F,$19,$01,$05,$66,$0E,$0C
  DEFB $10,$FE,$01,$B0,$13,$18,$00,$FD
  DEFB $13,$9B,$02,$9B,$08,$08,$C8,$15
  DEFB $18,$0C,$FE,$07,$9B,$0A,$9F,$FD
  DEFB $05,$9F,$19,$01,$05,$66,$0E,$0C
  DEFB $10,$FE,$07,$9B,$FD,$02,$9B,$0C
  DEFB $FF,$12,$9F,$FE,$95,$9F,$04,$9B
  DEFB $FD,$04,$9F,$19,$01,$05,$9F,$05
  DEFB $66,$0E,$0C,$10,$FF,$12,$9A,$04
  DEFB $9B,$13,$3D,$00,$02,$43,$FD,$14
  DEFB $9B,$05,$63,$10,$FF,$13,$9A,$01
  DEFB $B0,$04,$9A,$FD,$0A,$9A,$15,$18
  DEFB $14,$9B,$0C,$FE,$01,$B0,$04,$9B
  DEFB $FD,$15,$18,$14,$9B,$0C,$FF,$3D
  DEFB $9A,$04,$9B,$13,$3D,$00,$FD,$0A
  DEFB $9A,$05,$A0,$10,$FE,$04,$9B,$1D
  DEFB $79,$4C,$3D,$48,$62,$46,$FD,$0A
  DEFB $9A,$05,$A0,$10,$FE,$04,$9B,$FD
  DEFB $06,$30,$10,$FE,$03,$9A,$FD,$06
  DEFB $2A,$10,$FF,$FF,$4F,$01,$82,$FD
  DEFB $06,$32,$10,$FF,$11,$85,$03,$85
  DEFB $FD,$06,$38,$10,$FF,$11,$9A,$01
  DEFB $8F,$07,$9A,$FD,$08,$2C,$00,$02
  DEFB $9A,$1D,$FF,$11,$A4,$07,$A4,$01
  DEFB $90,$10,$9A,$8F,$FD,$02,$A4,$05
  DEFB $52,$10,$FE,$01,$90,$07,$A4,$FD
  DEFB $02,$A4,$08,$2C,$01,$05,$52,$19
  DEFB $01,$05,$53,$10,$FF,$11,$FF,$06
  DEFB $00,$FD,$06,$2C,$10,$FF,$11,$92
  DEFB $07,$92,$12,$24,$00,$FD,$02,$92
  DEFB $06,$1D,$19,$01,$08,$1A,$01,$08
  DEFB $1F,$00,$15,$24,$05,$76,$10,$FF
  DEFB $11,$A3,$07,$85,$FD,$05,$0B,$10
  DEFB $FF,$11,$A9,$07,$AA,$05,$A8,$FD
  DEFB $02,$AA,$13,$9D,$0A,$A9,$0C,$FE
  DEFB $07,$AA,$FD,$05,$1F,$10,$FF,$2C
  DEFB $A9,$FE,$13,$A9,$04,$A9,$01,$38
  DEFB $FD,$14,$9D,$0A,$A9,$04,$AA,$0C
  DEFB $FF,$11,$AD,$07,$AE,$FD,$06,$2B
  DEFB $10,$FF,$11,$A2,$07,$00,$FD,$02
  DEFB $00,$08,$4A,$00,$0C,$FF,$11,$B3
  DEFB $07,$B3,$FD,$02,$00,$08,$4B,$00
  DEFB $0C,$FF,$11,$A9,$0C,$A9,$1D,$58
  DEFB $59,$FD,$06,$35,$10,$FE,$01,$24
  DEFB $0C,$A9,$FD,$06,$38,$10,$FF,$11
  DEFB $A6,$0C,$A6,$1D,$58,$59,$FD,$06
  DEFB $35,$10,$FF,$11,$97,$07,$98,$FD
  DEFB $0A,$97,$02,$97,$08,$29,$00,$0C
  DEFB $FE,$01,$29,$0F,$98,$87,$FD,$06
  DEFB $32,$10,$FF,$11,$97,$FE,$1F,$97
  DEFB $01,$85,$0E,$97,$FD,$13,$97,$02
  DEFB $97,$08,$29,$00,$0C,$FF,$0A,$00
  DEFB $01,$87,$07,$98,$FD,$06,$1D,$0B
  DEFB $29,$FF,$11,$FF,$0C,$00,$FD,$06
  DEFB $24,$10,$FE,$FD,$02,$00,$0C,$FF
  DEFB $11,$00,$FD,$06,$27,$10,$FF,$18
  DEFB $FF,$12,$10,$00,$FD,$06,$24,$10
  DEFB $FE,$05,$00,$FD,$06,$2A,$10,$FF
  DEFB $18,$B5,$04,$B5,$FD,$12,$B5,$FD
  DEFB $0C,$FE,$03,$B5,$FD,$03,$B5,$0C
  DEFB $FF,$18,$9F,$04,$9F,$FD,$12,$9F
  DEFB $FD,$0C,$FE,$03,$9F,$FD,$03,$9F
  DEFB $0C,$FF,$18,$A8,$04,$A8,$FD,$12
  DEFB $A8,$FD,$0C,$FE,$03,$A8,$FD,$03
  DEFB $A8,$0C,$FF,$18,$A7,$04,$A7,$FD
  DEFB $12,$A7,$FD,$0C,$FE,$03,$A7,$FD
  DEFB $03,$A7,$0C,$FF,$18,$FF,$03,$00
  DEFB $FD,$06,$31,$10,$FE,$FD,$06,$23
  DEFB $10,$FF,$0F,$00,$FD,$01,$10,$FF
  DEFB $39,$A0,$FE,$39,$00,$04,$A0,$1D
  DEFB $B2,$B4,$FD,$05,$05,$10,$FE,$04
  DEFB $A0,$FD,$06,$2F,$10,$FE,$11,$96
  DEFB $FD,$05,$BA,$10,$FE,$11,$64,$FD
  DEFB $06,$31,$10,$FE,$FD,$06,$30,$10
  DEFB $FF,$19,$67,$04,$A0,$1D,$B3,$B4
  DEFB $FD,$05,$05,$10,$FF,$19,$66,$20
  DEFB $B3,$B4,$B2,$AF,$FD,$06,$2F,$10
  DEFB $FE,$04,$A0,$01,$B4,$FD,$05,$05
  DEFB $10,$FE,$1D,$B4,$B2,$FD,$05,$05
  DEFB $10,$FE,$09,$A0,$FD,$06,$2F,$10
  DEFB $FE,$01,$AF,$14,$54,$02,$FD,$06
  DEFB $1D,$0B,$BA,$FE,$01,$B3,$14,$54
  DEFB $02,$FD,$06,$1D,$0B,$B5,$FE,$FD
  DEFB $06,$2F,$10,$FF,$0A,$00,$1D,$B6
  DEFB $B9,$FD,$05,$AF,$19,$02,$05,$66
  DEFB $0B,$A7,$FF,$09,$00,$01,$BC,$15
  DEFB $02,$03,$FD,$0B,$BB,$FE,$01,$BC
  DEFB $FD,$05,$B9,$10,$FF,$3A,$5B,$01
  DEFB $BB,$13,$43,$00,$FD,$06,$2A,$10
  DEFB $FE,$01,$BB,$09,$92,$FD,$05,$B6
  DEFB $10,$FE,$01,$BB,$FD,$05,$B7,$15
  DEFB $43,$10,$FF,$0B,$00,$01,$BB,$13
  DEFB $43,$00,$FD,$14,$A0,$0B,$BD,$FF
  DEFB $0C,$00,$01,$BD,$FD,$05,$7B,$19
  DEFB $02,$05,$6F,$05,$66,$0E,$0C,$0B
  DEFB $A7,$FF,$95,$A0,$FE,$12,$A0,$1D
  DEFB $B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC
  DEFB $FD,$06,$31,$10,$FF,$12,$FF,$FE
  DEFB $95,$FF,$1D,$B5,$B6,$B7,$B8,$B9
  DEFB $BA,$BB,$BC,$FD,$05,$AD,$14,$00
  DEFB $10,$FF,$38,$00,$01,$81,$FD,$05
  DEFB $B5,$10,$FE,$FD,$06,$2F,$10,$FF
  DEFB $26,$A1,$01,$81,$FD,$06,$38,$10
  DEFB $FF,$21,$6A,$FE,$0E,$6A,$FE,$21
  DEFB $A0,$03,$A0,$FD,$05,$AA,$10,$FF
  DEFB $12,$FF,$FE,$95,$FF,$01,$AE,$FD
  DEFB $14,$00,$0B,$F9,$FF,$12,$8C,$13
  DEFB $3D,$00,$04,$8C,$FD,$06,$31,$10
  DEFB $FF,$12,$81,$13,$3D,$00,$FD,$04
  DEFB $00,$0C,$FF,$12,$8E,$13,$3D,$00
  DEFB $02,$43,$FD,$14,$81,$15,$11,$05
  DEFB $63,$10,$FF,$12,$FF,$13,$3D,$00
  DEFB $02,$43,$FD,$05,$63,$14,$00,$10
  DEFB $FF,$12,$A5,$FE,$95,$A5,$01,$15
  DEFB $FD,$12,$A5,$16,$05,$44,$08,$57
  DEFB $01,$10,$FF,$30,$00,$01,$15,$13
  DEFB $57,$00,$FD,$15,$57,$06,$1D,$0B
  DEFB $80,$FF,$95,$FF,$FE,$12,$FF,$11
  DEFB $7D,$1D,$97,$98,$99,$9A,$9B,$9C
  DEFB $9D,$9E,$9F,$A0,$A1,$FD,$05,$90
  DEFB $12,$00,$94,$10,$FE,$1D,$97,$98
  DEFB $99,$9A,$9B,$9C,$9D,$9E,$9F,$A0
  DEFB $A1,$FD,$05,$90,$12,$00,$95,$10
  DEFB $FF,$1E,$97,$FE,$95,$97,$FE,$12
  DEFB $97,$04,$97,$01,$87,$FD,$04,$97
  DEFB $0A,$97,$06,$1D,$1D,$FF,$1E,$97
  DEFB $FD,$06,$2E,$10,$FF,$26,$9A,$01
  DEFB $8E,$FD,$06,$2B,$10,$FF,$12,$FF
  DEFB $01,$91,$FD,$1B,$5B,$0D,$05,$56
  DEFB $12,$00,$90,$10,$FE,$FD,$04,$00
  DEFB $0C,$FF,$0E,$00,$FD,$1D,$FF,$0E
  DEFB $47,$05,$A7,$1D,$2E,$34,$FD,$05
  DEFB $65,$10,$FE,$20,$2E,$34,$FD,$06
  DEFB $19,$10,$FE,$FD,$05,$9B,$10,$FF
  DEFB $0E,$20,$1D,$C3,$C4,$FD,$05,$9B
  DEFB $10,$FE,$1D,$18,$51,$77,$66,$67
  DEFB $B3,$FD,$06,$2D,$10,$FF,$0E,$9C
  DEFB $01,$6C,$FD,$09,$9C,$10,$FF,$0E
  DEFB $A3,$1D,$0A,$0B,$FD,$82,$A3,$04
  DEFB $10,$FF,$0E,$9D,$03,$AA,$FD,$05
  DEFB $88,$10,$FF,$0E,$46,$01,$15,$FD
  DEFB $06,$2D,$10,$FF,$0E,$69,$01,$8B
  DEFB $FD,$06,$2D,$10,$FF,$0E,$8C,$13
  DEFB $3D,$00,$FD,$09,$8C,$10,$FE,$01
  DEFB $8B,$FD,$06,$2D,$10,$FF,$0E,$4B
  DEFB $01,$01,$FD,$05,$89,$10,$FF,$0E
  DEFB $9D,$01,$0E,$FD,$05,$CA,$10,$FF
  DEFB $0E,$FF,$03,$00,$FD,$09,$00,$10
  DEFB $FF,$1C,$FF,$FD,$06,$28,$10,$FF
  DEFB $1B,$81,$09,$81,$09,$82,$FD,$06
  DEFB $19,$10,$FE,$12,$0A,$00,$FD,$05
  DEFB $69,$10,$FE,$04,$82,$13,$22,$00
  DEFB $13,$37,$00,$FD,$05,$3C,$10,$FE
  DEFB $04,$82,$01,$7B,$FD,$14,$AF,$FE
  DEFB $04,$82,$FD,$08,$40,$00,$06,$1D
  DEFB $15,$11,$0A,$81,$1D,$FE,$04,$81
  DEFB $FD,$06,$2A,$10,$FF,$1A,$81,$04
  DEFB $82,$FD,$06,$2A,$10,$FE,$04,$81
  DEFB $FD,$15,$11,$0A,$81,$0C,$FF,$2A
  DEFB $81,$09,$81,$09,$82,$FD,$06,$23
  DEFB $10,$FE,$14,$0A,$F0,$FD,$06,$2A
  DEFB $10,$FE,$04,$88,$20,$16,$A6,$FD
  DEFB $05,$91,$10,$FE,$1D,$79,$4C,$3D
  DEFB $48,$62,$46,$FD,$05,$91,$10,$FE
  DEFB $13,$3D,$00,$02,$A6,$FD,$05,$91
  DEFB $10,$FE,$20,$16,$A6,$FD,$06,$30
  DEFB $10,$FE,$01,$A6,$FD,$08,$2B,$00
  DEFB $08,$3E,$00,$08,$0A,$FA,$0C,$FE
  DEFB $12,$1B,$00,$FD,$06,$30,$10,$FE
  DEFB $FD,$0F,$1B,$08,$0A,$FA,$08,$3E
  DEFB $00,$08,$2B,$00,$0C,$FF,$35,$81
  DEFB $09,$81,$09,$82,$FD,$06,$23,$10
  DEFB $FE,$FD,$06,$2F,$10,$FF,$2A,$88
  DEFB $09,$88,$FD,$06,$23,$10,$FE,$FD
  DEFB $06,$2E,$10,$FF,$45,$FF,$FD,$11
  DEFB $10,$FF,$25,$85,$07,$00,$FD,$05
  DEFB $06,$10,$FF,$26,$85,$07,$00,$01
  DEFB $0B,$FD,$15,$4E,$05,$07,$12,$00
  DEFB $0A,$1B,$5C,$0D,$0B,$0A,$FE,$07
  DEFB $00,$01,$0A,$FD,$05,$08,$10,$FF
  DEFB $26,$5B,$01,$09,$0F,$85,$0A,$FD
  DEFB $15,$4E,$05,$8E,$1B,$5D,$0D,$08
  DEFB $19,$01,$12,$A3,$0C,$14,$85,$10
  DEFB $FE,$01,$09,$FD,$06,$2F,$10,$FE
  DEFB $01,$08,$12,$35,$00,$FD,$1B,$5E
  DEFB $0D,$05,$37,$19,$01,$0B,$01,$FE
  DEFB $01,$08,$FD,$06,$2F,$10,$FE,$01
  DEFB $5A,$FD,$06,$2F,$10,$FF,$2C,$AB
  DEFB $FE,$13,$AB,$01,$5A,$04,$AB,$FD
  DEFB $1B,$5F,$0D,$06,$2F,$15,$35,$10
  DEFB $FF,$29,$87,$FE,$29,$86,$04,$87
  DEFB $04,$86,$02,$12,$FD,$14,$87,$05
  DEFB $60,$10,$FE,$04,$87,$04,$86,$01
  DEFB $12,$FD,$1B,$60,$0D,$14,$87,$08
  DEFB $1A,$00,$05,$10,$10,$FE,$09,$00
  DEFB $FD,$06,$23,$10,$FF,$29,$87,$09
  DEFB $86,$04,$87,$FD,$06,$30,$10,$FF
  DEFB $B0,$FF,$FE,$04,$00,$01,$12,$12
  DEFB $1A,$00,$FD,$0B,$19,$FF,$B0,$FF
  DEFB $FE,$03,$00,$01,$19,$12,$1A,$00
  DEFB $FD,$0B,$12,$FF,$17,$4C,$FE,$33
  DEFB $4C,$FE,$1D,$4C,$20,$27,$19,$1E
  DEFB $FD,$06,$21,$10,$FE,$1D,$27,$19
  DEFB $FD,$06,$38,$10,$FF,$17,$4C,$01
  DEFB $1E,$13,$30,$00,$FD,$15,$30,$0C
  DEFB $FE,$FD,$06,$2A,$10,$FF,$1D,$4C
  DEFB $01,$1E,$12,$30,$00,$FD,$15,$30
  DEFB $0C,$FE,$FD,$06,$2A,$10,$FF,$2F
  DEFB $4E,$01,$1E,$FD,$15,$30,$0C,$FF
  DEFB $25,$4C,$FE,$25,$00,$FE,$09,$00
  DEFB $01,$19,$12,$30,$00,$FD,$06,$32
  DEFB $10,$FE,$01,$19,$FD,$0B,$1A,$FF
  DEFB $0A,$00,$01,$1A,$13,$30,$00,$FD
  DEFB $0B,$19,$FF,$3C,$4C,$FE,$3C,$00
  DEFB $01,$19,$FD,$0B,$27,$FE,$01,$27
  DEFB $FD,$0B,$19,$FF,$04,$00,$01,$19
  DEFB $12,$30,$00,$FD,$0B,$27,$FF,$03
  DEFB $00,$01,$27,$12,$30,$00,$FD,$0B
  DEFB $19,$FF,$B0,$FF,$FE,$03,$00,$01
  DEFB $6E,$07,$93,$FD,$06,$15,$10,$FE
  DEFB $01,$6E,$FD,$0B,$6F,$FF,$04,$00
  DEFB $FE,$B0,$00,$01,$6F,$FD,$0B,$6E
  DEFB $FF,$25,$00,$01,$3B,$13,$1E,$00
  DEFB $FD,$0B,$3A,$FE,$01,$38,$13,$1E
  DEFB $00,$FD,$0B,$39,$FE,$01,$54,$13
  DEFB $1E,$00,$FD,$0B,$3A,$FE,$01,$73
  DEFB $FD,$06,$2E,$10,$FE,$01,$77,$12
  DEFB $22,$00,$FD,$06,$15,$10,$FE,$01
  DEFB $77,$FD,$06,$37,$10,$FE,$01,$58
  DEFB $FD,$0B,$59,$FE,$01,$59,$FD,$0B
  DEFB $5A,$FE,$20,$73,$14,$15,$5C,$FD
  DEFB $06,$15,$10,$FE,$01,$73,$FD,$06
  DEFB $37,$10,$FE,$FD,$06,$2E,$10,$FF
  DEFB $60,$47,$01,$2E,$FD,$05,$16,$10
  DEFB $FE,$01,$34,$FD,$05,$16,$10,$FF
  DEFB $0B,$00,$FE,$0B,$47,$12,$1D,$01
  DEFB $01,$2E,$FD,$1B,$61,$0D,$0B,$2F
  DEFB $FE,$12,$1D,$01,$01,$34,$FD,$1B
  DEFB $62,$0D,$0B,$35,$FE,$01,$8E,$09
  DEFB $9A,$09,$9B,$FD,$0B,$8F,$FE,$01
  DEFB $8E,$FD,$05,$57,$10,$FF,$0C,$00
  DEFB $FE,$01,$00,$01,$8F,$09,$9A,$09
  DEFB $9B,$FD,$0B,$8E,$FE,$01,$8F,$FD
  DEFB $05,$57,$10,$FF,$0C,$00,$FE,$03
  DEFB $00,$01,$AB,$13,$2D,$00,$FD,$0B
  DEFB $A8,$FF,$03,$00,$01,$AA,$13,$2E
  DEFB $00,$FD,$0B,$A9,$FF,$02,$00,$01
  DEFB $AA,$13,$2E,$00,$FD,$0B,$A9,$FF
  DEFB $0C,$00,$01,$A9,$13,$2F,$00,$FD
  DEFB $0B,$66,$FE,$01,$A9,$FD,$05,$28
  DEFB $10,$FF,$0B,$00,$FE,$04,$00,$01
  DEFB $A8,$13,$2D,$00,$FD,$0B,$AB,$FE
  DEFB $01,$A9,$13,$2E,$00,$FD,$0B,$AA
  DEFB $FF,$01,$00,$01,$A9,$13,$2E,$00
  DEFB $FD,$0B,$AA,$FF,$0B,$00,$01,$66
  DEFB $13,$2F,$00,$FD,$0B,$A9,$FE,$01
  DEFB $66,$FD,$05,$28,$10,$FE,$01,$67
  DEFB $FD,$05,$28,$10,$FF,$0B,$5D,$FE
  DEFB $16,$0B,$01,$63,$FD,$0B,$65,$FF
  DEFB $21,$58,$01,$B3,$FD,$05,$BF,$10
  DEFB $FE,$01,$08,$FD,$05,$8A,$10,$FE
  DEFB $01,$19,$FD,$05,$8C,$10,$FE,$01
  DEFB $56,$FD,$05,$93,$10,$FE,$01,$89
  DEFB $FD,$05,$95,$10,$FE,$01,$09,$FD
  DEFB $05,$96,$10,$FE,$01,$0E,$FD,$05
  DEFB $CA,$10,$FE,$01,$77,$13,$22,$00
  DEFB $FD,$05,$CB,$10,$FF,$21,$9D,$FE
  DEFB $21,$89,$01,$0E,$FD,$05,$CA,$10
  DEFB $FF,$21,$8D,$02,$65,$03,$8D,$FD
  DEFB $05,$8B,$10,$FE,$12,$34,$01,$FD
  DEFB $06,$2F,$10,$FE,$FD,$05,$2F,$1B
  DEFB $63,$0D,$08,$34,$01,$10,$FF,$21
  DEFB $A6,$FE,$21,$58,$03,$A6,$FD,$05
  DEFB $6D,$10,$FF,$21,$A7,$03,$A7,$FD
  DEFB $05,$97,$10,$FF,$21,$00,$FD,$06
  DEFB $21,$10,$FF,$21,$FF,$FD,$06,$24
  DEFB $10,$FF,$2B,$8C,$FE,$2B,$00,$20
  DEFB $48,$3D,$62,$79,$4C,$FD,$06,$31
  DEFB $10,$FE,$08,$8C,$FD,$06,$30,$10
  DEFB $FE,$01,$48,$FD,$15,$3D,$14,$8C
  DEFB $0B,$3F,$FE,$01,$3D,$FD,$15,$3D
  DEFB $14,$8C,$0B,$3E,$FE,$12,$24,$00
  DEFB $01,$62,$FD,$15,$3D,$14,$8C,$0B
  DEFB $6B,$FE,$01,$62,$FD,$06,$2E,$10
  DEFB $FE,$01,$79,$FD,$15,$3D,$14,$8C
  DEFB $0B,$84,$FE,$01,$4C,$FD,$15,$3D
  DEFB $14,$8C,$0B,$3E,$FE,$01,$46,$FD
  DEFB $05,$CE,$10,$FE,$13,$3D,$00,$FD
  DEFB $06,$2A,$10,$FE,$FD,$06,$31,$10
  DEFB $FF,$28,$8C,$12,$3D,$00,$03,$8C
  DEFB $FD,$08,$33,$05,$08,$21,$00,$0C
  DEFB $FE,$12,$3D,$00,$08,$8C,$FD,$06
  DEFB $19,$10,$FE,$01,$43,$FD,$1B,$64
  DEFB $0D,$08,$21,$00,$08,$33,$05,$0C
  DEFB $FE,$FD,$05,$61,$10,$FF,$2A,$8C
  DEFB $FD,$06,$31,$10,$FF,$28,$88,$FE
  DEFB $28,$4A,$09,$88,$FD,$06,$23,$10
  DEFB $FE,$03,$8A,$FD,$1B,$65,$0D,$0A
  DEFB $8A,$FE,$FD,$05,$1C,$14,$88,$10
  DEFB $FF,$68,$4A,$03,$88,$FD,$05,$1C
  DEFB $14,$88,$05,$A3,$10,$FF,$68,$FF
  DEFB $1D,$79,$4C,$3D,$48,$62,$46,$12
  DEFB $FD,$0C,$FE,$01,$A6,$FD,$0F,$0D
  DEFB $0F,$0D,$05,$A3,$10,$FE,$01,$16
  DEFB $13,$1B,$00,$FD,$0F,$1B,$0F,$0D
  DEFB $0F,$0D,$05,$A3,$10,$FE,$12,$13
  DEFB $3D,$00,$FD,$0C,$FF,$1B,$8A,$03
  DEFB $8A,$FD,$06,$2F,$10,$FE,$08,$8B
  DEFB $FD,$06,$19,$10,$FE,$04,$8B,$1D
  DEFB $3B,$38,$54,$FD,$05,$1D,$15,$1E
  DEFB $14,$8B,$10,$FE,$04,$8B,$01,$7D
  DEFB $FD,$1B,$66,$0D,$05,$1D,$15,$25
  DEFB $14,$8B,$1D,$FE,$04,$8B,$FD,$05
  DEFB $1E,$14,$8B,$10,$FF,$02,$00,$FE
  DEFB $0C,$00,$01,$51,$13,$1F,$00,$FD
  DEFB $0B,$18,$FE,$01,$51,$FD,$05,$28
  DEFB $10,$FF,$01,$00,$FE,$0B,$00,$01
  DEFB $18,$13,$1F,$00,$FD,$0B,$51,$FE
  DEFB $01,$18,$FD,$05,$28,$10,$FF,$17
  DEFB $20,$01,$67,$FD,$05,$75,$10,$FE
  DEFB $01,$66,$12,$2F,$00,$FD,$05,$75
  DEFB $10,$FE,$01,$A9,$12,$2F,$00,$FD
  DEFB $05,$75,$10,$FE,$01,$51,$12,$1F
  DEFB $00,$FD,$05,$75,$10,$FE,$01,$18
  DEFB $12,$1F,$00,$FD,$05,$75,$10,$FE
  DEFB $01,$77,$13,$22,$00,$FD,$06,$2A
  DEFB $10,$FE,$01,$77,$FD,$0E,$0D,$15
  DEFB $22,$0C,$FF,$23,$20,$FE,$17,$20
  DEFB $20,$51,$18,$66,$67,$A9,$FD,$06
  DEFB $19,$10,$FE,$09,$89,$FD,$06,$30
  DEFB $10,$FE,$13,$24,$00,$1D,$51,$18
  DEFB $FD,$05,$6A,$10,$FE,$01,$67,$FD
  DEFB $05,$6A,$10,$FE,$01,$66,$13,$2F
  DEFB $00,$FD,$06,$2A,$10,$FE,$01,$66
  DEFB $FD,$08,$2F,$01,$0C,$FE,$01,$A9
  DEFB $13,$2F,$00,$FD,$06,$2A,$10,$FE
  DEFB $01,$A9,$FD,$08,$2F,$01,$0C,$FE
  DEFB $13,$1F,$00,$FD,$06,$2A,$10,$FE
  DEFB $09,$89,$FD,$06,$2A,$10,$FE,$FD
  DEFB $15,$1F,$0C,$FF,$1D,$20,$01,$77
  DEFB $13,$22,$00,$FD,$0F,$0D,$15,$22
  DEFB $0C,$FE,$01,$77,$FD,$06,$2A,$0C
  DEFB $FF,$22,$20,$FE,$1D,$20,$20,$51
  DEFB $18,$66,$A9,$FD,$06,$24,$10,$FE
  DEFB $09,$89,$FD,$06,$30,$10,$FE,$01
  DEFB $66,$12,$2F,$00,$FD,$06,$2A,$10
  DEFB $FE,$01,$66,$FD,$15,$2F,$0C,$FE
  DEFB $01,$A9,$12,$2F,$00,$FD,$06,$2A
  DEFB $10,$FE,$01,$A9,$FD,$15,$2F,$0C
  DEFB $FE,$12,$1F,$00,$FD,$06,$2A,$10
  DEFB $FE,$04,$89,$FD,$15,$1F,$0C,$FF
  DEFB $60,$93,$FE,$26,$93,$07,$93,$FD
  DEFB $05,$3A,$10,$FF,$2D,$00,$04,$81
  DEFB $01,$6E,$FD,$15,$11,$12,$81,$36
  DEFB $05,$35,$0B,$6F,$FE,$01,$12,$FD
  DEFB $06,$2E,$10,$FE,$01,$BA,$FD,$14
  DEFB $A0,$0B,$AF,$FE,$20,$89,$1D,$2B
  DEFB $1B,$1A,$87,$1C,$2A,$B5,$B6,$B7
  DEFB $B8,$B9,$BB,$BC,$BD,$AF,$FD,$05
  DEFB $68,$10,$FE,$FD,$06,$1D,$05,$7B
  DEFB $19,$02,$05,$6F,$19,$01,$05,$66
  DEFB $08,$0C,$00,$FE,$01,$AF,$FD,$0B
  DEFB $15,$FE,$01,$1B,$FD,$0B,$20,$FE
  DEFB $01,$2A,$FD,$0B,$20,$FE,$01,$1A
  DEFB $FD,$0B,$27,$FE,$01,$87,$FD,$0B
  DEFB $29,$FE,$01,$1C,$FD,$0B,$1F,$FE
  DEFB $01,$AF,$FD,$0B,$15,$FE,$1D,$B6
  DEFB $B9,$BB,$BC,$FD,$14,$A0,$0B,$A7
  DEFB $FE,$01,$B5,$FD,$14,$A0,$0B,$B3
  DEFB $FE,$01,$B7,$FD,$14,$A0,$FE,$01
  DEFB $B8,$FD,$14,$A0,$0B,$12,$FE,$FD
  DEFB $0B,$21,$FF,$26,$5B,$01,$C2,$FD
  DEFB $15,$44,$06,$1D,$1D,$FF,$17,$20
  DEFB $12,$45,$00,$1D,$C3,$C4,$FD,$06
  DEFB $38,$10,$FE,$1D,$C3,$C4,$FD,$06
  DEFB $2A,$10,$FF,$23,$20,$12,$45,$00
  DEFB $09,$89,$1D,$C3,$C4,$FD,$06,$30
  DEFB $10,$FE,$1D,$C3,$C4,$FD,$06,$2E
  DEFB $10,$FF,$0B,$00,$01,$C3,$12,$45
  DEFB $00,$FD,$05,$28,$10,$FE,$01,$C3
  DEFB $12,$44,$00,$FD,$0B,$C4,$FE,$01
  DEFB $C3,$FD,$15,$45,$05,$BC,$19,$03
  DEFB $05,$BD,$0B,$C4,$FE,$01,$C5,$FD
  DEFB $0B,$C4,$FF,$0C,$00,$01,$C4,$12
  DEFB $45,$00,$FD,$05,$28,$10,$FE,$01
  DEFB $C4,$12,$44,$00,$FD,$0B,$C3,$FE
  DEFB $01,$C4,$FD,$0B,$C5,$FF,$14,$92
  DEFB $09,$92,$FD,$06,$23,$10,$FE,$01
  DEFB $C5,$FD,$1B,$67,$0D,$FE,$01,$C5
  DEFB $12,$0D,$FA,$FD,$0E,$46,$FE,$01
  DEFB $C5,$FD,$05,$5E,$19,$14,$0D,$FF
  DEFB $19,$48,$1D,$C3,$C4,$FD,$15,$45
  DEFB $05,$BB,$10,$FE,$20,$2E,$34,$FD
  DEFB $06,$1D,$10,$FE,$FD,$1B,$68,$0D
  DEFB $15,$1D,$0C,$FF,$95,$99,$1D,$8C
  DEFB $93,$FD,$14,$99,$1B,$69,$0D,$05
  DEFB $4F,$08,$28,$00,$10,$FF,$60,$5C
  DEFB $01,$8A,$FD,$05,$70,$10,$FF,$95
  DEFB $8C,$13,$3D,$00,$FD,$06,$31,$10
  DEFB $FF,$95,$81,$13,$3D,$00,$FD,$14
  DEFB $81,$08,$11,$00,$05,$63,$10,$FF
  DEFB $95,$FF,$13,$3D,$00,$FD,$05,$63
  DEFB $14,$00,$10,$FE,$02,$6E,$FD,$04
  DEFB $00,$0C,$FF,$95,$FF,$07,$93,$1F
  DEFB $A2,$FD,$04,$00,$05,$36,$10,$FE
  DEFB $07,$93,$FD,$14,$00,$14,$93,$05
  DEFB $3B,$10,$FF,$14,$FF,$07,$93,$1F
  DEFB $A2,$FD,$05,$36,$10,$FE,$07,$93
  DEFB $FD,$14,$00,$14,$93,$15,$36,$05
  DEFB $3B,$10,$FE,$FD,$06,$2E,$10,$FF
  DEFB $2E,$8E,$09,$8E,$FD,$06,$23,$10
  DEFB $FE,$01,$6E,$12,$36,$00,$FD,$1B
  DEFB $6A,$0D,$0A,$93,$15,$36,$05,$0F
  DEFB $1D,$FE,$FD,$06,$2F,$10,$FF,$0A
  DEFB $00,$01,$77,$12,$22,$00,$FD,$06
  DEFB $15,$10,$FE,$01,$77,$FD,$06,$37
  DEFB $10,$FF,$26,$95,$0E,$95,$01,$6C
  DEFB $12,$26,$00,$FD,$0A,$95,$08,$26
  DEFB $01,$05,$42,$1B,$6B,$0D,$10,$FE
  DEFB $0E,$96,$01,$6C,$FD,$06,$2A,$10
  DEFB $FE,$FD,$06,$2F,$10,$FF,$0A,$00
  DEFB $01,$6C,$0E,$96,$FD,$0B,$7C,$FF
  DEFB $0A,$00,$01,$7D,$13,$25,$00,$FD
  DEFB $0B,$69,$FF,$02,$00,$01,$7D,$13
  DEFB $25,$00,$FD,$0B,$69,$FF,$36,$B1
  DEFB $09,$B1,$FD,$06,$23,$10,$FE,$09
  DEFB $86,$FD,$06,$30,$10,$FE,$FD,$1B
  DEFB $6C,$0D,$05,$4A,$FE,$01,$8A,$07
  DEFB $AE,$FD,$05,$4C,$0A,$AD,$10,$FE
  DEFB $FD,$10,$FF,$17,$55,$01,$85,$FD
  DEFB $06,$38,$10,$FF,$17,$5A,$01,$A8
  DEFB $FD,$06,$38,$10,$FF,$2F,$4E,$01
  DEFB $85,$FD,$15,$27,$0C,$FE,$01,$A8
  DEFB $FD,$06,$24,$10,$FE,$01,$AB,$12
  DEFB $2D,$00,$FD,$15,$2D,$05,$74,$10
  DEFB $FE,$01,$AB,$FD,$15,$2D,$0C,$FF
  DEFB $27,$4F,$01,$82,$FD,$06,$2F,$10
  DEFB $FE,$01,$A9,$13,$24,$00,$FD,$06
  DEFB $2F,$10,$FE,$01,$A9,$FD,$1B,$6D
  DEFB $0D,$15,$2E,$06,$1D,$1D,$FF,$26
  DEFB $4F,$01,$A9,$12,$2E,$00,$FD,$06
  DEFB $2F,$10,$FE,$01,$A9,$FD,$15,$2E
  DEFB $0C,$FF,$26,$53,$01,$35,$12,$17
  DEFB $00,$FD,$15,$17,$06,$1D,$1D,$10
  DEFB $FE,$01,$35,$FD,$06,$2A,$10,$FF
  DEFB $27,$53,$01,$35,$13,$17,$00,$FD
  DEFB $15,$17,$0C,$FE,$01,$35,$FD,$06
  DEFB $2A,$10,$FF,$0A,$00,$01,$AF,$13
  DEFB $17,$00,$FD,$0B,$35,$FF,$09,$00
  DEFB $01,$35,$13,$17,$00,$FD,$0B,$AF
  DEFB $FF,$2F,$4E,$FD,$06,$24,$10,$FF
  DEFB $60,$FF,$FD,$06,$33,$10,$FF,$37
  DEFB $FF,$FD,$05,$4D,$10,$FF,$31,$FF
  DEFB $02,$AE,$11,$C8,$FD,$0B,$AE,$FE
  DEFB $FD,$06,$34,$0F,$0D,$10,$FF,$30
  DEFB $00,$FD,$06,$2F,$10,$FF,$67,$00
  DEFB $FE,$19,$67,$FD,$06,$07,$10,$FF
  DEFB $19,$00,$FD,$06,$14,$10,$FF,$19
  DEFB $FF,$11,$7D,$FD,$0C,$FE,$FD,$06
  DEFB $2F,$10,$FF,$44,$FF,$1D,$7A,$58
  DEFB $24,$FD,$06,$3A,$10,$FE,$FD,$06
  DEFB $2E,$10,$FF,$61,$FF,$FD,$05,$94
  DEFB $10,$FF,$32,$83,$07,$84,$FD,$06
  DEFB $0A,$10,$FF,$32,$8F,$07,$90,$FD
  DEFB $06,$0A,$10,$FF,$32,$9C,$01,$6C
  DEFB $FD,$06,$0A,$10,$FF,$32,$FF,$1E
  DEFB $81,$03,$00,$FD,$82,$00,$06,$10
  DEFB $FF,$32,$00,$FD,$06,$18,$10,$FF
  DEFB $32,$FF,$FD,$06,$31,$10,$FF,$64
  DEFB $00,$FD,$08,$0C,$00,$0C,$FF,$65
  DEFB $00,$FD,$08,$0C,$01,$0C,$FF,$00
  DEFB $00
MSG_TAB:
  DEFB $10,$00,$12,$31,$09,$FD,$19,$02
  DEFB $1B,$6E,$0D,$05,$04,$08,$31,$00
  DEFB $19,$01,$0B,$70,$FE,$FD,$08,$0C
  DEFB $00,$08,$31,$01,$10,$FF,$11,$00
  DEFB $FD,$08,$0C,$00,$08,$31,$00,$10
  DEFB $FF,$12,$00,$12,$31,$01,$FD,$08
  DEFB $31,$02,$10,$FF,$13,$00,$12,$31
  DEFB $02,$FD,$08,$31,$05,$10,$FF,$14
  DEFB $00,$12,$31,$05,$FD,$08,$31,$09
  DEFB $10,$FF,$14,$00,$FE,$13,$00,$FE
  DEFB $12,$00,$FD,$08,$0C,$00,$10,$FF
  DEFB $15,$00,$05,$A7,$0E,$A6,$FD,$13
  DEFB $A6,$05,$A2,$16,$10,$FE,$0E,$A6
  DEFB $FD,$13,$A6,$05,$15,$16,$10,$FF
  DEFB $16,$00,$06,$A7,$FD,$05,$18,$10
  DEFB $FF,$17,$00,$13,$14,$2C,$FD,$10
  DEFB $FE,$06,$A7,$FD,$19,$02,$05,$19
  DEFB $12,$A7,$2E,$05,$66,$0E,$0C,$10
  DEFB $FF,$18,$00,$12,$1C,$00,$12,$14
  DEFB $37,$FD,$15,$1C,$FF,$19,$00,$FD
  DEFB $08,$3C,$00,$10,$FF,$1A,$00,$14
  DEFB $33,$01,$FD,$0E,$21,$0F,$33,$05
  DEFB $25,$10,$FE,$FD,$15,$3D,$19,$01
  DEFB $05,$26,$14,$8C,$05,$66,$0E,$0C
  DEFB $10,$FF,$1B,$00,$04,$8A,$FD,$14
  DEFB $8A,$05,$27,$19,$02,$05,$66,$0E
  DEFB $0C,$10,$FE,$14,$33,$01,$FD,$0E
  DEFB $21,$0F,$33,$05,$25,$10,$FE,$FD
  DEFB $15,$3D,$19,$01,$05,$26,$14,$8C
  DEFB $19,$02,$05,$66,$0E,$0C,$10,$FF
  DEFB $1C,$00,$13,$3D,$00,$FD,$15,$3D
  DEFB $13,$8C,$10,$FF,$1D,$00,$FD,$05
  DEFB $8D,$0B,$58,$FF,$1E,$00,$FD,$08
  DEFB $20,$00,$10,$FF,$1F,$00,$13,$34
  DEFB $00,$FD,$10,$FE,$FD,$05,$2D,$05
  DEFB $66,$0E,$0C,$10,$FF,$20,$00,$13
  DEFB $34,$01,$FD,$05,$2E,$10,$FF,$21
  DEFB $00,$04,$81,$13,$22,$00,$FD,$15
  DEFB $11,$0E,$37,$0A,$81,$08,$4C,$00
  DEFB $05,$92,$10,$FE,$FD,$0E,$37,$10
  DEFB $FF,$22,$00,$FD,$08,$37,$00,$08
  DEFB $3C,$00,$10,$FF,$23,$00,$0F,$AF
  DEFB $7B,$0A,$A7,$FD,$05,$40,$12,$AF
  DEFB $F0,$10,$FF,$28,$00,$01,$58,$0F
  DEFB $AF,$F0,$0A,$A7,$FD,$05,$8F,$12
  DEFB $AF,$7B,$10,$FE,$0F,$AF,$F0,$FD
  DEFB $12,$AF,$7B,$FF,$24,$00,$12,$28
  DEFB $01,$FD,$05,$50,$0B,$F9,$FF,$25
  DEFB $00,$10,$A4,$90,$0C,$9A,$FD,$12
  DEFB $A4,$90,$05,$51,$05,$66,$0E,$0C
  DEFB $10,$FF,$26,$00,$FD,$05,$58,$10
  DEFB $FF,$27,$00,$FD,$19,$01,$05,$5A
  DEFB $FE,$04,$81,$11,$7F,$FD,$12,$81
  DEFB $95,$15,$11,$0A,$81,$0B,$94,$FE
  DEFB $04,$81,$FD,$12,$81,$94,$15,$11
  DEFB $0A,$81,$0B,$95,$FE,$04,$82,$11
  DEFB $7F,$FD,$12,$82,$94,$0B,$95,$FE
  DEFB $04,$82,$FD,$12,$82,$95,$0B,$94
  DEFB $FE,$10,$81,$94,$10,$82,$94,$FD
  DEFB $0B,$94,$FE,$FD,$19,$02,$0B,$95
  DEFB $FF,$29,$00,$13,$19,$00,$FD,$05
  DEFB $A5,$19,$04,$05,$6F,$05,$66,$0E
  DEFB $0C,$0B,$0C,$FF,$2A,$00,$FD,$0F
  DEFB $54,$FE,$12,$54,$02,$FD,$05,$B0
  DEFB $05,$B1,$10,$FE,$13,$54,$00,$FD
  DEFB $10,$FE,$FD,$05,$B0,$05,$B2,$05
  DEFB $7B,$19,$02,$05,$6F,$05,$66,$FE
  DEFB $01,$B5,$FD,$0B,$B3,$FE,$01,$B7
  DEFB $FD,$0B,$0E,$FE,$01,$B8,$FD,$0B
  DEFB $12,$FE,$01,$BA,$FD,$0B,$AF,$FE
  DEFB $FD,$0B,$A7,$FF,$2B,$00,$01,$B2
  DEFB $09,$A0,$FD,$10,$FE,$FD,$08,$42
  DEFB $01,$05,$AC,$19,$01,$14,$A0,$08
  DEFB $09,$0F,$15,$53,$08,$0C,$00,$0B
  DEFB $B1,$FF,$2C,$00,$08,$92,$FD,$19
  DEFB $02,$05,$BE,$19,$01,$0B,$0D,$FF
  DEFB $2E,$00,$FD,$0E,$1B,$19,$02,$05
  DEFB $1A,$08,$02,$00,$08,$0C,$00,$81
  DEFB $FE,$0F,$81,$FC,$FD,$12,$82,$36
  DEFB $FE,$0F,$82,$FC,$FD,$12,$81,$36
  DEFB $FE,$15,$0D,$05,$FD,$08,$0D,$00
  DEFB $0F,$32,$10,$FE,$FD,$08,$37,$00
  DEFB $0F,$32,$0F,$0D,$0F,$0D,$0F,$0D
  DEFB $0F,$0D,$0F,$0D,$19,$04,$0B,$0D
  DEFB $FF,$FF,$FF,$FD,$10,$FF,$00,$00
TABKEY1_TAB:
  DEFB $54,$1B,$75,$75,$75,$1B,$1A,$07
  DEFB $81,$57,$06,$75,$75,$75,$06,$1A
  DEFB $00,$81,$56,$10,$75,$75,$75,$10
  DEFB $14,$06,$81,$51,$02,$75,$75,$75
  DEFB $02,$10,$06,$81,$50,$1B,$10,$75
  DEFB $F5,$53,$1B,$02,$75,$F5,$52,$06
  DEFB $10,$75,$F5,$5D,$06,$02,$75,$F5
  DEFB $5C,$00,$75,$75,$75,$00,$05,$75
  DEFB $F5,$5F,$11,$75,$75,$75,$11,$1A
  DEFB $02,$9B,$5E,$1C,$1B,$75,$75,$10
  DEFB $1B,$01,$10,$1C,$1B,$01,$9A,$59
  DEFB $10,$0D,$1C,$01,$19,$10,$14,$03
  DEFB $1A,$00,$01,$F5,$5B,$10,$0D,$14
  DEFB $18,$19,$1A,$1A,$1E,$19,$75,$75
  DEFB $F5,$5A,$1C,$75,$75,$75,$1C,$1B
  DEFB $03,$10,$1C,$1B,$03,$F5,$45,$04
  DEFB $00,$1C,$81,$44,$12,$10,$01,$75
  DEFB $12,$07,$14,$17,$01,$14,$1E,$90
  DEFB $47,$11,$07,$1A,$05,$07,$10,$18
  DEFB $9A,$46,$05,$00,$01,$F5,$41,$12
  DEFB $1C,$03,$90,$40,$05,$1C,$16,$9E
  DEFB $43,$12,$1A,$75,$F5,$42,$1A,$05
  DEFB $10,$9B,$4D,$02,$10,$14,$87,$4C
  DEFB $06,$14,$0C,$75,$06,$05,$10,$14
  DEFB $0C,$10,$19,$19,$16,$14,$19,$99
  DEFB $4F,$1A,$13,$13,$75,$10,$0D,$01
  DEFB $9C,$4E,$1A,$1B,$75,$75,$19,$1C
  DEFB $12,$1D,$06,$01,$07,$1C,$1C,$12
  DEFB $1B,$1C,$10,$0D,$05,$99,$49,$1D
  DEFB $10,$19,$85,$48,$16,$19,$1A,$06
  DEFB $06,$1D,$00,$81,$4B,$01,$1C,$10
  DEFB $F5,$4A,$00,$1B,$01,$1C,$00,$1B
  DEFB $11,$9A,$75,$11,$1A,$1A,$07,$01
  DEFB $07,$14,$05,$16,$10,$19,$19,$18
  DEFB $10,$01,$94,$74,$07,$10,$14,$91
  DEFB $77,$19,$1A,$16,$9E,$76,$00,$1B
  DEFB $19,$9A,$71,$17,$07,$10,$94,$70
  DEFB $16,$19,$1C,$98,$73,$05,$00,$06
  DEFB $1D,$06,$1D,$1A,$03,$05,$07,$10
  DEFB $06,$18,$1A,$03,$10,$17,$10,$1B
  DEFB $91,$72,$05,$00,$19,$99,$7D,$17
  DEFB $14,$1C,$19,$05,$1A,$00,$07,$10
  DEFB $18,$05,$81,$7C,$13,$1C,$07,$10
  DEFB $06,$1D,$1A,$1A,$14,$1C,$18,$F5
  DEFB $7F,$13,$1C,$19,$99,$7E,$06,$14
  DEFB $1C,$19,$19,$14,$00,$9B,$79,$1C
  DEFB $1B,$06,$10,$05,$00,$01,$F5,$78
  DEFB $1F,$00,$18,$05,$19,$10,$14,$85
  DEFB $7B,$02,$14,$03,$90,$7A,$01,$00
  DEFB $07,$1B,$01,$02,$1C,$86,$65,$02
  DEFB $1C,$06,$9D,$64,$13,$00,$16,$1E
  DEFB $05,$1C,$06,$06,$17,$14,$19,$19
  DEFB $06,$1D,$1C,$01,$17,$00,$12,$92
  DEFB $67,$10,$14,$01,$F5,$66,$07,$14
  DEFB $1C,$06,$19,$1C,$13,$81,$61,$06
  DEFB $1C,$01,$75,$19,$1C,$10,$F5,$60
  DEFB $07,$00,$17,$75,$05,$1A,$19,$9C
  DEFB $63,$05,$19,$14,$8C,$62,$06,$02
  DEFB $1C,$98,$6D,$05,$07,$14,$8C,$6C
  DEFB $13,$19,$0C,$F5,$6F,$01,$1A,$00
  DEFB $96,$6E,$12,$1A,$10,$86,$69,$16
  DEFB $07,$14,$82,$68,$16,$1A,$1A,$19
  DEFB $11,$1A,$00,$86,$6B,$00,$1B,$11
  DEFB $90,$6A,$06,$14,$03,$90,$15,$19
  DEFB $1A,$14,$91,$14,$07,$10,$06,$81
  DEFB $17,$13,$07,$10,$90,$16,$00,$1B
  DEFB $13,$87,$11,$16,$1D,$14,$06,$13
  DEFB $1A,$19,$19,$16,$14,$01,$96,$10
  DEFB $06,$16,$1A,$87,$13,$02,$10,$19
  DEFB $99,$12,$18,$1C,$07,$87,$1D,$13
  DEFB $07,$1C,$90,$1C,$07,$00,$17,$97
  DEFB $1F,$19,$1C,$04,$80,$1E,$17,$07
  DEFB $1C,$11,$11,$07,$14,$82,$19,$05
  DEFB $1A,$07,$81,$18,$16,$1D,$14,$9B
  DEFB $1B,$02,$1D,$10,$10,$02,$1C,$1B
  DEFB $96,$1A,$01,$1A,$07,$96,$05,$16
  DEFB $1A,$03,$90,$04,$17,$10,$11,$F5
  DEFB $07,$13,$1A,$07,$9E,$06,$07,$1A
  DEFB $1A,$13,$16,$10,$1C,$99,$01,$01
  DEFB $10,$18,$85,$00,$17,$1A,$0D,$F5
  DEFB $03,$17,$14,$0C,$F5,$02,$1C,$1B
  DEFB $19,$90,$0D,$1B,$1A,$01,$10,$02
  DEFB $14,$07,$1B,$18,$10,$06,$06,$07
  DEFB $00,$1B,$10,$19,$10,$01,$81,$0C
  DEFB $03,$14,$19,$99,$0F,$12,$07,$14
  DEFB $81,$0E,$17,$00,$01,$01,$06,$01
  DEFB $14,$87,$09,$10,$14,$12,$99,$08
  DEFB $05,$10,$1B,$81,$0B,$1D,$14,$18
  DEFB $98,$0A,$17,$14,$19,$10,$1D,$14
  DEFB $0C,$F5,$35,$1D,$1C,$01,$75,$06
  DEFB $01,$14,$17,$1E,$1C,$19,$19,$14
  DEFB $01,$01,$94,$34,$11,$1C,$12,$F5
  DEFB $37,$13,$10,$10,$91,$36,$14,$19
  DEFB $19,$F5,$31,$03,$10,$07,$97,$30
  DEFB $04,$00,$1C,$90,$33,$14,$17,$07
  DEFB $94,$32,$1D,$1A,$16,$00,$13,$10
  DEFB $10,$75,$0D,$0C,$0F,$0F,$05,$19
  DEFB $00,$12,$06,$10,$06,$94,$3D,$11
  DEFB $07,$1C,$9B,$3C,$13,$1C,$06,$1D
  DEFB $07,$10,$19,$9C,$3F,$05,$19,$14
  DEFB $84,$D4,$19,$14,$18,$85,$D6,$1D
  DEFB $0C,$11,$87,$D0,$06,$01,$14,$81
  DEFB $D3,$17,$1A,$02,$F5,$D2,$14,$07
  DEFB $07,$9A,$DD,$17,$1A,$01,$01,$13
  DEFB $19,$14,$06,$16,$1A,$1B,$81,$DC
  DEFB $1E,$10,$0C,$75,$1E,$10,$0C,$86
  DEFB $DF,$11,$0C,$1B,$94,$D9,$17,$1A
  DEFB $14,$81,$D8,$06,$16,$07,$9A,$DB
  DEFB $06,$01,$14,$93,$DA,$11,$07,$14
  DEFB $92,$C4,$03,$1C,$14,$99,$C7,$1A
  DEFB $07,$17,$F5,$C6,$01,$07,$1A,$99
  DEFB $C0,$01,$1D,$07,$9A,$C2,$07,$1A
  DEFB $05,$10,$16,$1A,$1C,$99,$CC,$13
  DEFB $19,$1A,$00,$17,$14,$12,$F5,$CF
  DEFB $17,$14,$07,$75,$06,$01,$10,$90
  DEFB $C9,$06,$1E,$10,$99,$C8,$06,$01
  DEFB $1A,$9B,$CB,$12,$1C,$1B,$92,$CA
  DEFB $12,$19,$1A,$83,$F5,$17,$07,$1A
  DEFB $9A,$F4,$14,$19,$01,$94,$F7,$16
  DEFB $19,$1A,$96,$F6,$11,$1C,$14,$98
  DEFB $F1,$12,$1A,$17,$99,$F0,$16,$1A
  DEFB $1C,$1B,$07,$14,$07,$90,$F3,$1E
  DEFB $1B,$1C,$13,$11,$14,$12,$92,$F2
  DEFB $07,$1C,$1B,$92,$FD,$16,$07,$1A
  DEFB $82,$FC,$06,$02,$1A,$07,$17,$07
  DEFB $1A,$14,$06,$14,$17,$07,$14,$07
  DEFB $18,$06,$14,$18,$18,$80,$FE,$12
  DEFB $10,$18,$F5,$F9,$06,$16,$10,$85
  DEFB $F8,$10,$12,$12,$75,$10,$12,$12
  DEFB $06,$1B,$10,$06,$81,$FA,$1B,$00
  DEFB $12,$92,$E5,$16,$07,$1A,$06,$14
  DEFB $16,$07,$9A,$E4,$03,$1C,$1A,$19
  DEFB $06,$01,$07,$94,$E7,$16,$1D,$10
  DEFB $06,$05,$1C,$10,$96,$E6,$05,$1C
  DEFB $16,$01,$05,$14,$1C,$1B,$18,$14
  DEFB $06,$81,$E1,$03,$14,$1B,$90,$E0
  DEFB $1B,$10,$16,$9E,$E3,$03,$14,$06
  DEFB $10,$18,$1C,$1B,$92,$AF,$01,$1D
  DEFB $10,$1B,$14,$1B,$11,$75,$14,$19
  DEFB $06,$1A,$73,$75,$75,$F5,$AE,$1C
  DEFB $01,$75,$75,$01,$1D,$10,$98,$A9
  DEFB $14,$12,$14,$1C,$07,$10,$05,$90
  DEFB $55,$00
TABKEY2_TAB:
  DEFB $45,$39,$3A,$36,$B4,$44,$39,$3A
  DEFB $36,$B7,$47,$39,$3A,$36,$B6,$46
  DEFB $39,$3A,$36,$B1,$41,$39,$3A,$36
  DEFB $B0,$40,$39,$3A,$36,$B3,$43,$39
  DEFB $3A,$36,$B2,$42,$39,$3A,$36,$BD
  DEFB $4D,$39,$3A,$36,$BC,$4C,$39,$3A
  DEFB $36,$BF,$4F,$39,$3A,$36,$B9,$4E
  DEFB $39,$3A,$36,$B8,$49,$39,$3A,$36
  DEFB $BB,$48,$39,$3A,$36,$BA,$4B,$39
  DEFB $3A,$36,$A5,$4A,$39,$3A,$36,$A4
  DEFB $75,$39,$3A,$36,$A7,$74,$39,$3A
  DEFB $36,$A6,$77,$39,$3A,$36,$A1,$76
  DEFB $39,$3A,$36,$A0,$71,$39,$3A,$36
  DEFB $A3,$70,$39,$3A,$36,$A2,$73,$39
  DEFB $3A,$36,$AD,$72,$39,$3A,$36,$AC
  DEFB $7D,$39,$3A,$36,$AF,$7C,$3B,$3A
  DEFB $21,$B4,$7F,$3B,$3A,$21,$B6,$7E
  DEFB $3B,$3A,$21,$B1,$79,$3B,$3A,$21
  DEFB $B0,$78,$3B,$3A,$21,$B3,$7B,$31
  DEFB $30,$34,$B1,$AF,$05,$19,$00,$86
  DEFB $55,$00
LOC_TAB:
  DEFB $00,$FD,$01,$02,$05,$03,$07,$04
  DEFB $02,$05,$08,$06,$06,$07,$FF,$D1
  DEFB $D8,$E1,$72,$AB,$68,$00,$FD,$03
  DEFB $03,$02,$01,$04,$07,$08,$06,$07
  DEFB $04,$FF,$C9,$8E,$3C,$2A,$4B,$68
  DEFB $00,$FD,$01,$02,$03,$04,$02,$05
  DEFB $08,$01,$04,$07,$FF,$C9,$8E,$3C
  DEFB $2A,$4D,$68,$00,$FD,$01,$02,$03
  DEFB $03,$02,$05,$06,$01,$04,$06,$FF
  DEFB $C9,$8E,$3C,$2A,$4B,$68,$00,$FD
  DEFB $01,$01,$03,$04,$05,$03,$06,$07
  DEFB $04,$06,$FF,$C9,$8E,$3C,$2A,$4C
  DEFB $68,$00,$FD,$01,$02,$05,$01,$04
  DEFB $07,$03,$04,$02,$05,$FF,$C9,$8E
  DEFB $3C,$2A,$4B,$68,$00,$FD,$01,$02
  DEFB $04,$06,$03,$03,$07,$01,$02,$05
  DEFB $06,$08,$FF,$C9,$8E,$3C,$2A,$96
  DEFB $8F,$00,$FD,$04,$6F,$FF,$D1,$18
  DEFB $EC,$DF,$00,$FD,$02,$50,$01,$54
  DEFB $0B,$0A,$04,$0A,$FF,$4D,$19,$E3
  DEFB $28,$EC,$BD,$0D,$00,$FD,$04,$0B
  DEFB $03,$09,$0C,$09,$FF,$D1,$28,$E1
  DEFB $77,$4C,$2B,$00,$FD,$03,$0A,$FF
  DEFB $D5,$B8,$E1,$7F,$00,$FD,$09,$52
  DEFB $07,$8C,$FF,$D1,$38,$E1,$7F,$00
  DEFB $FF,$04,$0E,$09,$0F,$03,$7F,$01
  DEFB $0F,$02,$7F,$FF,$D1,$46,$8F,$00
  DEFB $FF,$01,$0F,$02,$7E,$03,$0D,$04
  DEFB $12,$FF,$D1,$58,$ED,$16,$00,$FF
  DEFB $05,$A7,$06,$10,$07,$10,$0A,$0D
  DEFB $04,$7E,$08,$7F,$FF,$35,$00,$FF
  DEFB $06,$10,$04,$0F,$08,$0F,$07,$0D
  DEFB $05,$7F,$03,$A7,$FF,$35,$00,$FF
  DEFB $01,$12,$04,$15,$08,$7E,$02,$7F
  DEFB $07,$7E,$03,$0F,$05,$0F,$FF,$2C
  DEFB $8E,$D1,$78,$6E,$1E,$6F,$00,$FF
  DEFB $02,$11,$01,$13,$03,$0E,$07,$7E
  DEFB $05,$0F,$FF,$2C,$8E,$D1,$7F,$00
  DEFB $FF,$02,$12,$04,$14,$03,$10,$01
  DEFB $7E,$05,$0F,$06,$7E,$07,$10,$FF
  DEFB $2C,$8E,$D1,$78,$6E,$1A,$6F,$00
  DEFB $FF,$02,$15,$03,$13,$06,$7E,$05
  DEFB $0F,$01,$7E,$04,$7F,$08,$7E,$FF
  DEFB $D1,$88,$E2,$C8,$6E,$1A,$6F,$00
  DEFB $FF,$01,$14,$03,$11,$0A,$16,$02
  DEFB $7E,$08,$0F,$07,$10,$04,$7E,$06
  DEFB $0F,$FF,$D1,$88,$E2,$C8,$6E,$1E
  DEFB $6F,$00,$FF,$01,$17,$09,$15,$FF
  DEFB $D1,$98,$ED,$1A,$00,$FD,$02,$16
  DEFB $01,$18,$03,$91,$09,$91,$FF,$4D
  DEFB $19,$E3,$2F,$00,$FD,$02,$17,$FF
  DEFB $D1,$C8,$EC,$B8,$6E,$04,$D0,$B6
  DEFB $FF,$00,$FF,$FF,$DE,$B8,$08,$ED
  DEFB $54,$00,$FF,$01,$1B,$02,$1C,$FF
  DEFB $C3,$8E,$D5,$4F,$00,$FF,$02,$1A
  DEFB $04,$1D,$0A,$20,$FF,$1A,$8E,$23
  DEFB $00,$FF,$01,$1A,$04,$2A,$0A,$1F
  DEFB $FF,$1E,$8E,$23,$00,$FF,$03,$1B
  DEFB $0A,$21,$FF,$1A,$8E,$3F,$8E,$23
  DEFB $00,$FF,$04,$1F,$06,$27,$FF,$D1
  DEFB $E8,$E1,$7F,$00,$FF,$01,$27,$03
  DEFB $1E,$0B,$28,$07,$28,$09,$1C,$04
  DEFB $22,$06,$23,$FF,$3D,$86,$EE,$AE
  DEFB $96,$FF,$00,$FF,$02,$27,$04,$21
  DEFB $08,$23,$09,$1B,$0A,$78,$06,$B0
  DEFB $FF,$3D,$86,$EE,$57,$E9,$6F,$00
  DEFB $FF,$02,$22,$0B,$25,$07,$23,$03
  DEFB $20,$09,$1D,$06,$25,$FF,$3D,$86
  DEFB $EE,$57,$E6,$06,$FF,$00,$FF,$69
  DEFB $21,$0B,$26,$03,$1F,$05,$23,$08
  DEFB $26,$FF,$3D,$86,$EE,$AE,$60,$6F
  DEFB $00,$FF,$05,$20,$06,$21,$07,$1F
  DEFB $08,$22,$0B,$36,$03,$27,$FF,$D0
  DEFB $98,$ED,$1F,$26,$00,$FF,$01,$25
  DEFB $02,$26,$09,$88,$04,$88,$FF,$D2
  DEFB $12,$A4,$FF,$00,$FF,$02,$24,$0C
  DEFB $21,$09,$2B,$03,$B0,$07,$21,$FF
  DEFB $1A,$8E,$3F,$8E,$3B,$00,$FF,$03
  DEFB $29,$0C,$22,$09,$30,$01,$24,$05
  DEFB $22,$FF,$1E,$8E,$3F,$8E,$3B,$00
  DEFB $FF,$01,$20,$02,$1F,$07,$1E,$04
  DEFB $23,$06,$21,$08,$22,$FF,$D6,$7D
  DEFB $0D,$00,$FF,$04,$29,$06,$1F,$0C
  DEFB $1F,$0A,$82,$09,$85,$FF,$D2,$2F
  DEFB $00,$FF,$03,$28,$04,$26,$FF,$4D
  DEFB $DA,$F2,$68,$E1,$7F,$00,$FF,$04
  DEFB $33,$0B,$33,$03,$1C,$FF,$1E,$8E
  DEFB $3F,$8E,$23,$00,$FF,$09,$2C,$0A
  DEFB $25,$FF,$D1,$0D,$0D,$8E,$D2,$02
  DEFB $A5,$1F,$00,$FD,$09,$2E,$0A,$2B
  DEFB $FF,$D2,$38,$E1,$72,$A5,$0F,$00
  DEFB $FD,$FF,$8F,$00,$FD,$0A,$2C,$FF
  DEFB $D2,$48,$E1,$7F,$00,$FD,$0A,$4E
  DEFB $0C,$2E,$FF,$D0,$EE,$32,$00,$FF
  DEFB $0A,$26,$09,$32,$FF,$D2,$57,$0A
  DEFB $8E,$5A,$5E,$B5,$B5,$D9,$5B,$AF
  DEFB $00,$FF,$FF,$8F,$00,$FF,$0A,$30
  DEFB $09,$33,$FF,$A5,$D5,$E4,$D6,$2F
  DEFB $00,$FF,$01,$8A,$03,$2A,$0C,$2A
  DEFB $09,$34,$0A,$32,$FF,$D1,$0D,$0D
  DEFB $8E,$3C,$00,$FF,$0A,$33,$FF,$4D
  DEFB $5E,$54,$97,$0A,$8E,$DC,$61,$7F
  DEFB $00,$FD,$0A,$4A,$0C,$34,$FF,$D0
  DEFB $EE,$32,$00,$FF,$0C,$23,$FF,$A5
  DEFB $DD,$82,$A2,$A5,$2F,$00,$FD,$09
  DEFB $36,$0A,$38,$07,$7A,$FF,$DE,$08
  DEFB $E3,$2F,$00,$FD,$09,$37,$FF,$D2
  DEFB $64,$FD,$A6,$00,$FD,$0A,$38,$03
  DEFB $3A,$FF,$D2,$78,$ED,$04,$00,$FD
  DEFB $0A,$3B,$04,$39,$08,$54,$FF,$D2
  DEFB $D8,$05,$ED,$28,$00,$FD,$02,$3C
  DEFB $FF,$D2,$88,$ED,$1B,$00,$FD,$01
  DEFB $3B,$02,$3D,$09,$4E,$03,$4E,$FF
  DEFB $D7,$65,$5D,$AF,$9F,$00,$FD,$01
  DEFB $3C,$FF,$D7,$70,$8E,$CE,$2A,$57
  DEFB $00,$FF,$04,$3D,$03,$40,$05,$40
  DEFB $07,$3F,$02,$3F,$FF,$D6,$91,$0E
  DEFB $CE,$2A,$55,$00,$FF,$02,$48,$06
  DEFB $3E,$01,$47,$05,$47,$FF,$D6,$91
  DEFB $0E,$CE,$2A,$55,$00,$FF,$02,$41
  DEFB $03,$42,$04,$3E,$08,$3E,$07,$43
  DEFB $01,$55,$FF,$0D,$80,$8E,$CE,$2A
  DEFB $56,$00,$FF,$05,$42,$06,$40,$02
  DEFB $47,$01,$43,$03,$44,$FF,$0D,$80
  DEFB $8E,$CE,$2A,$56,$00,$FF,$04,$40
  DEFB $08,$43,$02,$41,$07,$44,$06,$55
  DEFB $05,$A6,$FF,$0D,$80,$8E,$CE,$2A
  DEFB $56,$00,$FF,$08,$41,$02,$41,$05
  DEFB $42,$03,$42,$06,$40,$04,$40,$FF
  DEFB $D2,$AF,$00,$FF,$03,$45,$04,$47
  DEFB $06,$41,$01,$42,$FF,$D6,$91,$0E
  DEFB $CE,$2A,$55,$00,$FD,$0A,$46,$FF
  DEFB $D8,$F8,$ED,$2F,$2A,$55,$00,$FD
  DEFB $04,$53,$09,$53,$FF,$D2,$66,$28
  DEFB $E4,$BB,$62,$2A,$57,$00,$FF,$03
  DEFB $44,$08,$3F,$01,$41,$06,$41,$05
  DEFB $41,$FF,$D6,$91,$0E,$CE,$2A,$55
  DEFB $00,$FD,$09,$4A,$FF,$D2,$B2,$A5
  DEFB $7F,$00,$FD,$FF,$8F,$00,$FD,$09
  DEFB $35,$03,$35,$04,$48,$0A,$48,$FF
  DEFB $1E,$8E,$DF,$EF,$00,$FD,$FF,$8F
  DEFB $00,$FD,$FF,$8F,$00,$FD,$FF,$8F
  DEFB $00,$FD,$09,$2F,$0A,$3C,$FF,$D0
  DEFB $EE,$32,$00,$FD,$FF,$8F,$00,$FD
  DEFB $02,$51,$07,$52,$01,$09,$FF,$4D
  DEFB $19,$E3,$28,$ED,$2D,$00,$FD,$01
  DEFB $50,$FF,$D1,$C8,$EC,$B8,$6E,$DA
  DEFB $FD,$0B,$6F,$00,$FD,$04,$50,$03
  DEFB $53,$0A,$0C,$FF,$D1,$28,$E3,$28
  DEFB $6E,$11,$6F,$00,$FD,$04,$52,$03
  DEFB $46,$06,$56,$02,$A4,$09,$56,$0A
  DEFB $A4,$FF,$D1,$28,$E3,$28,$ED,$5F
  DEFB $26,$00,$FD,$02,$09,$FF,$D2,$E2
  DEFB $BE,$32,$00,$FF,$02,$40,$07,$42
  DEFB $01,$84,$FF,$D2,$CE,$3B,$00,$FD
  DEFB $02,$53,$07,$53,$04,$57,$0A,$57
  DEFB $FF,$1A,$8E,$DF,$EF,$00,$FD,$09
  DEFB $56,$03,$58,$06,$63,$FF,$3C,$00
  DEFB $FD,$04,$57,$01,$66,$09,$59,$FF
  DEFB $DC,$48,$E1,$72,$A6,$3F,$00,$FD
  DEFB $04,$57,$0A,$A5,$01,$66,$07,$AC
  DEFB $09,$5A,$FF,$DC,$48,$E1,$7F,$00
  DEFB $FD,$0A,$58,$FF,$D0,$1E,$17,$00
  DEFB $FF,$FF,$2A,$58,$00,$FD,$01,$5D
  DEFB $FF,$DE,$88,$ED,$99,$00,$FD,$06
  DEFB $5F,$01,$5E,$09,$5F,$0A,$5E,$02
  DEFB $5C,$FF,$D3,$68,$E3,$CF,$00,$FD
  DEFB $04,$6A,$03,$5D,$FF,$D3,$68,$E3
  DEFB $22,$A5,$3F,$00,$FD,$09,$62,$0A
  DEFB $5D,$01,$60,$04,$62,$0B,$60,$03
  DEFB $5D,$FF,$60,$95,$D8,$E3,$2F,$00
  DEFB $FD,$01,$6C,$02,$5F,$0C,$5F,$FF
  DEFB $D3,$38,$E1,$7F,$00,$FD,$FF,$8F
  DEFB $00,$FD,$0A,$5F,$03,$5F,$FF,$D2
  DEFB $CE,$4B,$D9,$C5,$4F,$00,$FD,$0B
  DEFB $65,$07,$57,$01,$64,$05,$67,$FF
  DEFB $D3,$22,$A5,$9F,$00,$FD,$04,$68
  DEFB $02,$63,$FF,$D3,$22,$A5,$AF,$00
  DEFB $FD,$0C,$64,$FF,$DA,$FD,$0B,$8E
  DEFB $D3,$12,$A5,$BF,$00,$FD,$04,$67
  DEFB $03,$58,$FF,$DA,$88,$ED,$2E,$86
  DEFB $E0,$E6,$FF,$00,$FD,$03,$66,$08
  DEFB $63,$04,$6D,$FF,$DA,$88,$ED,$2E
  DEFB $86,$E1,$16,$FF,$00,$FD,$04,$69
  DEFB $03,$64,$FF,$DE,$58,$ED,$1B,$5B
  DEFB $57,$00,$FD,$03,$68,$FF,$50,$52
  DEFB $D9,$C5,$D8,$E1,$7F,$00,$FD,$FF
  DEFB $2E,$8E,$17,$00,$FD,$0A,$55,$FF
  DEFB $D8,$F8,$ED,$2F,$2A,$55,$00,$FD
  DEFB $02,$60,$FF,$D3,$38,$E1,$7F,$00
  DEFB $FD,$09,$67,$0A,$6E,$01,$6E,$02
  DEFB $67,$FF,$D7,$42,$68,$E3,$2F,$00
  DEFB $FD,$08,$6D,$02,$6D,$FF,$D3,$48
  DEFB $6E,$11,$6F,$00,$FD,$04,$6E,$03
  DEFB $08,$FF,$D3,$48,$6E,$0E,$6F,$00
  DEFB $FD,$03,$71,$FF,$D3,$5F,$00,$FF
  DEFB $03,$6A,$0A,$72,$04,$70,$FF,$D3
  DEFB $68,$E1,$72,$A5,$DF,$00,$FD,$09
  DEFB $71,$01,$74,$03,$73,$FF,$D7,$46
  DEFB $28,$ED,$99,$2A,$AF,$00,$FF,$04
  DEFB $72,$FF,$DE,$98,$ED,$1A,$00,$FD
  DEFB $01,$75,$04,$72,$07,$73,$FF,$D3
  DEFB $0D,$03,$8E,$D1,$BF,$00,$FD,$01
  DEFB $74,$08,$74,$0A,$76,$03,$73,$FF
  DEFB $D3,$0D,$03,$8E,$3C,$00,$FD,$09
  DEFB $75,$04,$75,$FF,$58,$5B,$4B,$8E
  DEFB $17,$00,$FD,$09,$78,$04,$79,$FF
  DEFB $57,$1C,$8E,$D0,$4F,$00,$FF,$09
  DEFB $20,$0A,$77,$FF,$D0,$48,$E3,$BF
  DEFB $00,$FD,$03,$77,$09,$77,$07,$8B
  DEFB $05,$7A,$FF,$D6,$82,$A5,$7F,$00
  DEFB $FD,$08,$79,$03,$7B,$01,$37,$FF
  DEFB $57,$96,$08,$ED,$1B,$2A,$5E,$00
  DEFB $FD,$04,$7A,$FF,$DA,$E4,$FB,$4C
  DEFB $92,$A5,$EF,$00,$FD,$09,$6C,$04
  DEFB $7D,$FF,$D0,$EE,$32,$00,$FD,$03
  DEFB $7C,$FF,$D1,$18,$EC,$DF,$00,$FF
  DEFB $01,$0F,$02,$7F,$03,$7F,$04,$7E
  DEFB $06,$B2,$07,$7E,$08,$0E,$FF,$35
  DEFB $00,$FF,$01,$7E,$02,$10,$04,$10
  DEFB $05,$80,$06,$7E,$08,$0F,$FF,$35
  DEFB $00,$FF,$01,$0F,$02,$7F,$03,$7E
  DEFB $04,$10,$0B,$81,$FF,$D3,$72,$6F
  DEFB $00,$FF,$0C,$80,$FF,$DC,$7F,$00
  DEFB $FF,$09,$28,$04,$A3,$FF,$60,$DA
  DEFB $F9,$8E,$DA,$8B,$5B,$00,$FF,$FF
  DEFB $8F,$00,$FD,$02,$55,$01,$79,$FF
  DEFB $D3,$98,$ED,$3A,$00,$FF,$0A,$28
  DEFB $FF,$A5,$D5,$85,$B9,$8E,$17,$00
  DEFB $FF,$0A,$29,$FF,$D3,$8F,$00,$FF
  DEFB $FF,$D3,$FF,$00,$FF,$02,$8A,$0A
  DEFB $24,$FF,$4B,$B5,$B5,$BB,$4C,$54
  DEFB $AF,$00,$FF,$FF,$8F,$00,$FF,$02
  DEFB $33,$0B,$33,$01,$88,$FF,$B5,$F5
  DEFB $2B,$5B,$62,$00,$FD,$06,$79,$07
  DEFB $95,$FF,$56,$B5,$BD,$AF,$95,$B7
  DEFB $0A,$8E,$17,$00,$FD,$04,$0C,$03
  DEFB $8D,$FF,$D9,$78,$E3,$38,$6E,$11
  DEFB $6F,$00,$FD,$03,$8E,$04,$8C,$FF
  DEFB $D9,$78,$E3,$32,$A5,$F6,$8F,$00
  DEFB $FD,$04,$8D,$03,$93,$FF,$57,$1C
  DEFB $8E,$CB,$D0,$D2,$A5,$F6,$8F,$00
  DEFB $FD,$02,$90,$FF,$D3,$C8,$E1,$72
  DEFB $A6,$0F,$00,$FD,$01,$8F,$FF,$D3
  DEFB $C8,$E1,$7F,$00,$FD,$03,$92,$0A
  DEFB $17,$09,$92,$04,$17,$FF,$D3,$E8
  DEFB $ED,$1B,$00,$FD,$04,$91,$0A,$91
  DEFB $FF,$D1,$18,$EC,$DF,$00,$FD,$04
  DEFB $8E,$03,$A4,$05,$A4,$FF,$D9,$78
  DEFB $E3,$28,$6E,$0E,$6F,$68,$00,$FF
  DEFB $08,$A4,$01,$A1,$0B,$A1,$FF,$56
  DEFB $8E,$CB,$D0,$DF,$00,$FF,$06,$8B
  DEFB $01,$A0,$0B,$A0,$FF,$56,$8E,$CB
  DEFB $D0,$DF,$00,$FF,$02,$A1,$01,$97
  DEFB $FF,$30,$E1,$7F,$00,$FF,$02,$96
  DEFB $01,$98,$FF,$30,$E1,$7F,$00,$FF
  DEFB $02,$97,$08,$99,$FF,$30,$E1,$7F
  DEFB $00,$FF,$02,$9A,$05,$98,$FF,$30
  DEFB $E1,$7F,$00,$FF,$01,$99,$04,$9B
  DEFB $FF,$30,$E1,$7F,$00,$FF,$01,$9C
  DEFB $03,$9A,$FF,$30,$E1,$7F,$00,$FF
  DEFB $02,$9B,$06,$9D,$FF,$30,$E1,$7F
  DEFB $00,$FF,$02,$9E,$07,$9C,$FF,$30
  DEFB $E1,$7F,$00,$FF,$02,$9F,$01,$9D
  DEFB $FF,$30,$E1,$7F,$00,$FF,$02,$A0
  DEFB $01,$9E,$FF,$30,$E1,$7F,$00,$FF
  DEFB $02,$95,$01,$9F,$FF,$30,$E1,$7F
  DEFB $00,$FF,$02,$94,$01,$96,$FF,$30
  DEFB $E1,$7F,$00,$FF,$FF,$2A,$62,$00
  DEFB $FD,$03,$82,$FF,$D3,$D8,$ED,$3F
  DEFB $00,$FD,$02,$93,$01,$94,$06,$53
  DEFB $09,$53,$08,$93,$FF,$D2,$DF,$00
  DEFB $FD,$09,$59,$0A,$5C,$FF,$D9,$88
  DEFB $08,$ED,$E8,$8E,$D9,$9F,$00,$FD
  DEFB $08,$42,$FF,$58,$52,$31,$ED,$1B
  DEFB $00,$FF,$02,$A7,$03,$A7,$04,$10
  DEFB $08,$0F,$06,$A8,$FF,$35,$00,$FF
  DEFB $07,$A7,$FF,$DB,$79,$00,$FD,$FF
  DEFB $DA,$8F,$00,$FD,$03,$AB,$09,$AB
  DEFB $FF,$DE,$08,$ED,$04,$00,$FF,$0A
  DEFB $AA,$04,$AA,$FF,$D0,$48,$E3,$BF
  DEFB $00,$FD,$06,$59,$09,$59,$FF,$D9
  DEFB $88,$08,$ED,$B8,$62,$8E,$D9,$9F
  DEFB $00,$FD,$09,$AC,$FF,$DB,$86,$28
  DEFB $ED,$99,$74,$C2,$4F,$00,$FF,$FF
  DEFB $A6,$09,$B5,$B4,$B5,$86,$1F,$00
  DEFB $FF,$FF,$D6,$9E,$D6,$60,$8E,$A7
  DEFB $83,$FF,$00,$FF,$07,$20,$04,$25
  DEFB $FF,$D2,$3A,$56,$52,$DB,$E7,$0A
  DEFB $00,$FF,$FF,$35,$00,$FF,$07,$7E
  DEFB $FF,$35,$8E,$D3,$72,$6F,$00,$FF
  DEFB $0B,$B4,$02,$B2,$01,$B4,$03,$B2
  DEFB $04,$B2,$FF,$57,$90,$2E,$D4,$0F
  DEFB $00,$FF,$0C,$B3,$02,$B3,$FF,$D5
  DEFB $38,$ED,$EA,$00,$FF,$01,$B7,$06
  DEFB $B7,$04,$B7,$08,$B6,$02,$B6,$07
  DEFB $B6,$03,$B6,$09,$BC,$0A,$BC,$FF
  DEFB $C7,$ED,$EA,$74,$C2,$4C,$00,$FF
  DEFB $06,$B8,$04,$B8,$08,$B8,$02,$B7
  DEFB $07,$B7,$03,$B9,$05,$B9,$01,$B9
  DEFB $09,$BC,$FF,$C7,$ED,$42,$74,$C2
  DEFB $4C,$00,$FF,$01,$B8,$06,$B8,$04
  DEFB $B8,$08,$B8,$02,$B5,$03,$B6,$05
  DEFB $B6,$09,$BC,$0A,$0E,$FF,$C7,$ED
  DEFB $16,$74,$C2,$4C,$00,$FF,$06,$BA
  DEFB $04,$BA,$08,$BA,$01,$B9,$02,$B7
  DEFB $07,$B7,$03,$B7,$09,$BC,$0A,$12
  DEFB $FF,$C7,$E2,$C8,$ED,$17,$74,$C2
  DEFB $4C,$00,$FF,$06,$B6,$04,$B6,$08
  DEFB $B6,$01,$B6,$05,$B6,$02,$BA,$07
  DEFB $B6,$03,$B6,$09,$BC,$FF,$C7,$ED
  DEFB $42,$74,$C2,$4C,$00,$FF,$06,$B9
  DEFB $01,$B9,$05,$B9,$04,$B8,$08,$B8
  DEFB $02,$B8,$03,$B8,$09,$BC,$0A,$AF
  DEFB $FF,$C7,$E1,$E8,$E3,$F7,$4C,$24
  DEFB $CF,$00,$FF,$0A,$BC,$FF,$D4,$32
  DEFB $68,$10,$E1,$FA,$74,$C2,$4C,$00
  DEFB $FF,$0A,$B6,$FF,$5D,$60,$52,$61
  DEFB $5D,$8E,$51,$9B,$5F,$DF,$D8,$0B
  DEFB $E9,$B5,$BD,$BE,$74,$C2,$4C,$00
  DEFB $FF,$0B,$BE,$01,$BE,$FF,$DA,$FA
  DEFB $5E,$4B,$A5,$DD,$9C,$5D,$52,$B5
  DEFB $58,$E3,$2F,$00,$FF,$0C,$BD,$01
  DEFB $BF,$02,$BD,$FF,$D4,$48,$E1,$7F
  DEFB $00,$FF,$02,$BF,$07,$C0,$FF,$D4
  DEFB $48,$E1,$7F,$00,$FF,$06,$BF,$01
  DEFB $C1,$03,$C2,$FF,$D4,$48,$E1,$7F
  DEFB $00,$FF,$02,$C0,$01,$C3,$FF,$D4
  DEFB $48,$E1,$7F,$00,$FF,$0C,$C0,$04
  DEFB $C0,$FF,$95,$59,$4C,$5D,$5B,$52
  DEFB $4C,$B5,$58,$E1,$7F,$00,$FF,$02
  DEFB $C1,$FF,$5B,$94,$C9,$AA,$00,$FF
  DEFB $FF,$55,$52,$4F,$5D,$00,$FF,$FF
  DEFB $4C,$51,$B5,$64,$B9,$5B,$80,$8E
  DEFB $B5,$B5,$D9,$56,$52,$A7,$4C,$29
  DEFB $00,$FD,$09,$AD,$02,$AD,$0A,$C7
  DEFB $01,$C7,$FF,$D4,$58,$E3,$2F,$00
  DEFB $FD,$09,$C6,$0C,$C6,$02,$C6,$FF
  DEFB $D4,$58,$E1,$7F,$00,$00
TABKEY_TAB:
  DEFB $00,$38,$01,$D1,$DB,$55,$8D,$47
  DEFB $4D,$81,$78,$22,$32,$A8,$D0,$82
  DEFB $68,$04,$8C,$A8,$D9,$A8,$21,$78
  DEFB $29,$06,$01,$50,$95,$85,$69,$5D
  DEFB $5B,$52,$4C,$B5,$58,$D4,$62,$68
  DEFB $95,$D4,$C5,$12,$BD,$69,$10,$1A
  DEFB $82,$17,$88,$C3,$83,$A6,$48,$04
  DEFB $80,$85,$BD,$9A,$64,$80,$6D,$9C
  DEFB $81,$D8,$D4,$98,$CB,$78,$00,$37
  DEFB $02,$01,$C9,$83,$C8,$08,$32,$AF
  DEFB $00,$37,$02,$01,$C9,$83,$C8,$08
  DEFB $32,$AF,$00,$37,$02,$01,$C9,$83
  DEFB $C8,$08,$32,$AF,$00,$37,$02,$01
  DEFB $C9,$83,$C8,$08,$32,$AF,$00,$37
  DEFB $02,$01,$C9,$83,$C8,$08,$32,$AF
  DEFB $00,$37,$02,$01,$C9,$83,$C8,$08
  DEFB $32,$AF,$00,$3A,$8C,$68,$09,$D4
  DEFB $B8,$D4,$A8,$09,$01,$D1,$18,$CD
  DEFB $78,$82,$90,$60,$11,$F8,$D4,$74
  DEFB $D8,$D4,$C8,$D6,$91,$02,$18,$12
  DEFB $64,$82,$2D,$4F,$26,$8D,$4E,$57
  DEFB $DB,$D8,$52,$5D,$78,$00,$38,$01
  DEFB $4D,$19,$1A,$6B,$1E,$83,$28,$22
  DEFB $D0,$2D,$78,$59,$26,$8C,$A8,$01
  DEFB $D5,$02,$BD,$51,$26,$78,$82,$90
  DEFB $60,$1C,$48,$D4,$74,$D8,$D4,$C8
  DEFB $D6,$91,$02,$18,$58,$59,$59,$58
  DEFB $A5,$25,$D9,$80,$1C,$BD,$0D,$82
  DEFB $20,$16,$0B,$5B,$57,$26,$8D,$E3
  DEFB $4B,$9D,$0B,$85,$25,$D7,$8F,$00
  DEFB $37,$D5,$70,$90,$1C,$BD,$0D,$80
  DEFB $21,$0F,$0E,$8C,$D8,$08,$01,$D1
  DEFB $28,$17,$64,$86,$66,$BE,$4C,$29
  DEFB $06,$01,$D0,$15,$D5,$25,$59,$80
  DEFB $51,$0D,$9B,$80,$81,$02,$46,$66
  DEFB $18,$D6,$91,$38,$D6,$AA,$80,$1D
  DEFB $5B,$67,$67,$66,$E4,$CD,$56,$29
  DEFB $06,$D9,$C8,$1D,$8D,$49,$8C,$B6
  DEFB $77,$8F,$00,$37,$02,$10,$11,$8C
  DEFB $D8,$08,$01,$D1,$28,$17,$64,$81
  DEFB $02,$48,$06,$A5,$5D,$0A,$31,$D5
  DEFB $02,$B0,$BA,$4C,$5B,$B5,$D4,$C5
  DEFB $12,$B1,$27,$8F,$00,$38,$01,$D1
  DEFB $38,$17,$80,$B4,$FB,$5B,$8C,$38
  DEFB $3A,$80,$60,$1D,$49,$8C,$B8,$22
  DEFB $6A,$ED,$BE,$58,$5B,$70,$A8,$E5
  DEFB $99,$5B,$52,$55,$6A,$8D,$E3,$D6
  DEFB $95,$25,$D7,$88,$01,$D1,$0D,$0D
  DEFB $8D,$08,$A8,$0A,$0B,$01,$D9,$78
  DEFB $32,$81,$F5,$DA,$80,$91,$01,$E0
  DEFB $E7,$86,$6E,$4C,$81,$0D,$49,$8C
  DEFB $B8,$06,$1D,$80,$BD,$69,$10,$24
  DEFB $80,$6D,$95,$81,$0D,$5A,$80,$80
  DEFB $1D,$5B,$78,$67,$00,$68,$37,$05
  DEFB $01,$D1,$48,$A5,$E5,$BC,$42,$BD
  DEFB $69,$DB,$E5,$B9,$98,$D0,$BA,$80
  DEFB $3D,$42,$78,$81,$0D,$14,$84,$D5
  DEFB $2A,$C6,$A8,$BD,$0D,$80,$91,$01
  DEFB $17,$8F,$00,$37,$D6,$90,$1D,$15
  DEFB $8D,$5C,$D0,$D8,$D0,$82,$68,$09
  DEFB $01,$2C,$80,$51,$01,$18,$0B,$D5
  DEFB $D8,$D4,$28,$06,$D6,$99,$52,$D9
  DEFB $D8,$D0,$B8,$08,$3A,$78,$82,$90
  DEFB $60,$15,$49,$62,$D0,$38,$22,$01
  DEFB $D7,$D8,$D6,$95,$25,$D6,$48,$12
  DEFB $78,$00,$37,$05,$D8,$08,$35,$78
  DEFB $00,$37,$05,$D8,$08,$35,$78,$00
  DEFB $37,$02,$10,$1E,$0F,$2D,$80,$81
  DEFB $02,$C8,$D1,$77,$8F,$00,$37,$05
  DEFB $D1,$78,$08,$10,$2C,$64,$8D,$57
  DEFB $09,$01,$D4,$6D,$29,$78,$66,$E4
  DEFB $D8,$10,$D4,$6D,$29,$80,$65,$19
  DEFB $55,$4D,$80,$A0,$3D,$5D,$8D,$B0
  DEFB $8D,$9C,$8D,$AF,$4C,$51,$8D,$5D
  DEFB $64,$85,$6B,$54,$26,$81,$05,$65
  DEFB $80,$25,$E5,$7D,$5F,$D8,$27,$86
  DEFB $7F,$00,$37,$02,$10,$1A,$0F,$2D
  DEFB $80,$81,$02,$C8,$D1,$77,$8F,$00
  DEFB $37,$02,$10,$1A,$0F,$2D,$8D,$18
  DEFB $81,$02,$C6,$48,$C3,$83,$A8,$06
  DEFB $D9,$C8,$58,$56,$DA,$F5,$85,$EA
  DEFB $8D,$63,$26,$64,$8D,$23,$83,$F7
  DEFB $8F,$00,$37,$02,$10,$1E,$0F,$2D
  DEFB $8D,$18,$81,$02,$C6,$48,$D6,$48
  DEFB $01,$3F,$82,$25,$6D,$9C,$62,$82
  DEFB $78,$D2,$0A,$66,$54,$64,$8D,$69
  DEFB $D6,$60,$81,$38,$06,$A5,$25,$D5
  DEFB $D2,$68,$01,$60,$DB,$D9,$5B,$85
  DEFB $FD,$9C,$96,$77,$88,$D9,$D9,$70
  DEFB $A8,$D9,$C8,$58,$55,$4D,$8D,$19
  DEFB $81,$28,$22,$DB,$2A,$80,$91,$01
  DEFB $E8,$0B,$11,$78,$00,$37,$D6,$A2
  DEFB $68,$02,$10,$D1,$A8,$08,$10,$D1
  DEFB $96,$6E,$98,$05,$01,$A5,$1D,$A6
  DEFB $58,$60,$8D,$3A,$80,$85,$85,$25
  DEFB $56,$77,$88,$01,$D0,$98,$D5,$96
  DEFB $48,$4D,$19,$32,$8D,$08,$A8,$D8
  DEFB $81,$A8,$16,$12,$78,$00,$37,$05
  DEFB $01,$D0,$96,$48,$4D,$19,$1A,$6B
  DEFB $1E,$83,$2D,$0D,$78,$80,$1D,$0F
  DEFB $80,$51,$0F,$0E,$82,$18,$D0,$8A
  DEFB $80,$AD,$6C,$80,$12,$78,$D1,$B7
  DEFB $8F,$00,$37,$02,$10,$CD,$80,$80
  DEFB $14,$D1,$93,$27,$88,$29,$06,$01
  DEFB $25,$CB,$81,$28,$22,$01,$D0,$C8
  DEFB $D6,$9D,$BE,$06,$D0,$B6,$6E,$52
  DEFB $64,$8D,$06,$07,$06,$D6,$D8,$1D
  DEFB $67,$78,$00,$37,$02,$10,$DE,$B8
  DEFB $08,$01,$D8,$98,$D1,$C8,$D5,$46
  DEFB $48,$66,$E6,$30,$7D,$63,$A8,$56
  DEFB $5E,$4C,$51,$8D,$F9,$8D,$6E,$8D
  DEFB $CA,$83,$A8,$09,$55,$52,$4F,$5D
  DEFB $67,$66,$6B,$E6,$3D,$70,$2B,$C3
  DEFB $83,$A6,$77,$88,$C3,$81,$0D,$54
  DEFB $80,$60,$1D,$7D,$80,$BC,$A8,$10
  DEFB $66,$E6,$3D,$B7,$26,$67,$66,$6B
  DEFB $E6,$3D,$67,$67,$83,$A8,$34,$8D
  DEFB $78,$81,$02,$C8,$3D,$78,$66,$E4
  DEFB $D8,$D1,$88,$3A,$81,$0D,$46,$D2
  DEFB $98,$06,$D7,$09,$4D,$78,$67,$00
  DEFB $37,$D6,$90,$15,$71,$C8,$D7,$18
  DEFB $08,$10,$23,$A8,$C3,$81,$0D,$54
  DEFB $78,$81,$61,$28,$3A,$83,$48,$D6
  DEFB $38,$BD,$5F,$81,$03,$D8,$0B,$D7
  DEFB $88,$10,$5D,$60,$05,$3F,$A8,$D8
  DEFB $80,$91,$05,$59,$4F,$5D,$80,$B5
  DEFB $BD,$0A,$82,$21,$02,$3A,$85,$B5
  DEFB $E5,$75,$72,$68,$BC,$48,$10,$2C
  DEFB $8D,$6B,$26,$8D,$BE,$95,$68,$5D
  DEFB $58,$50,$9D,$9D,$78,$80,$51,$02
  DEFB $F0,$81,$03,$D8,$06,$01,$27,$64
  DEFB $8D,$09,$8D,$1F,$26,$78,$00,$3A
  DEFB $70,$5B,$98,$D6,$91,$01,$A0,$F2
  DEFB $D8,$23,$8D,$56,$D0,$38,$D8,$B8
  DEFB $D0,$88,$14,$09,$10,$3D,$78,$00
  DEFB $3A,$70,$5B,$98,$02,$10,$1E,$0F
  DEFB $2D,$80,$81,$02,$36,$48,$D7,$42
  DEFB $68,$D0,$38,$D8,$B8,$D0,$88,$14
  DEFB $09,$10,$3D,$78,$00,$37,$D6,$91
  DEFB $01,$A8,$23,$8D,$56,$D8,$B8,$D0
  DEFB $88,$14,$09,$10,$DE,$B8,$08,$10
  DEFB $3F,$78,$00,$37,$05,$01,$27,$81
  DEFB $78,$D7,$A8,$22,$5B,$5E,$A5,$D2
  DEFB $68,$56,$94,$C5,$1D,$9C,$52,$4C
  DEFB $B5,$58,$D1,$E8,$0B,$01,$DD,$B8
  DEFB $5E,$A2,$BD,$CA,$8D,$70,$26,$81
  DEFB $0D,$54,$64,$81,$5A,$80,$C0,$91
  DEFB $01,$18,$0B,$1A,$11,$78,$00,$37
  DEFB $04,$D0,$B8,$01,$CB,$D0,$D8,$02
  DEFB $10,$1E,$80,$E0,$F2,$D8,$08,$10
  DEFB $3D,$78,$82,$90,$6D,$9C,$58,$D9
  DEFB $D8,$3B,$80,$91,$0F,$0E,$80,$BD
  DEFB $8B,$8D,$08,$80,$A0,$91,$02,$37
  DEFB $8F,$00,$37,$02,$10,$1A,$80,$E0
  DEFB $F2,$D8,$08,$10,$3D,$8D,$56,$01
  DEFB $D5,$98,$D0,$F8,$50,$58,$9A,$81
  DEFB $4D,$6C,$81,$05,$0C,$47,$88,$D8
  DEFB $B8,$D0,$88,$16,$12,$80,$A0,$91
  DEFB $02,$3A,$80,$B2,$90,$6D,$9C,$83
  DEFB $B8,$09,$10,$1A,$11,$78,$00,$38
  DEFB $10,$1A,$81,$10,$F2,$D8,$08,$10
  DEFB $3D,$80,$4D,$0B,$81,$0E,$1A,$8E
  DEFB $3F,$64,$8D,$9E,$8D,$59,$80,$45
  DEFB $5D,$AF,$98,$55,$58,$58,$56,$A8
  DEFB $C3,$83,$A7,$8F,$00,$37,$02,$10
  DEFB $1E,$81,$10,$F2,$D8,$08,$10,$3D
  DEFB $64,$80,$4D,$0B,$81,$0E,$1E,$8E
  DEFB $3F,$78,$00,$37,$04,$D0,$B8,$01
  DEFB $D0,$98,$DB,$2D,$FD,$8D,$1F,$26
  DEFB $80,$51,$0D,$9B,$80,$81,$03,$D7
  DEFB $8F,$00,$37,$05,$01,$D0,$52,$55
  DEFB $1D,$A6,$8D,$EC,$81,$05,$D6,$05
  DEFB $88,$3F,$A6,$48,$07,$06,$A5,$DB
  DEFB $4C,$54,$2B,$22,$DA,$68,$56,$D9
  DEFB $C5,$79,$5B,$80,$8B,$5B,$56,$A8
  DEFB $0B,$B5,$65,$65,$E5,$75,$2D,$AD
  DEFB $78,$8D,$03,$8D,$8B,$8D,$08,$80
  DEFB $A1,$61,$01,$18,$21,$78,$00,$37
  DEFB $05,$10,$3B,$80,$91,$0E,$1A,$8E
  DEFB $3F,$78,$80,$1D,$03,$8D,$10,$DC
  DEFB $58,$D7,$4A,$85,$25,$DA,$8D,$0D
  DEFB $85,$E5,$9C,$88,$D6,$C8,$10,$3F
  DEFB $64,$8C,$BD,$0D,$A8,$D0,$88,$1E
  DEFB $80,$B0,$E7,$8F,$00,$37,$05,$10
  DEFB $3B,$80,$91,$0E,$1E,$8E,$3F,$64
  DEFB $80,$1D,$03,$8D,$10,$DC,$58,$D7
  DEFB $4A,$85,$25,$DA,$8D,$0D,$85,$E5
  DEFB $9C,$8A,$8D,$6C,$81,$03,$F6,$48
  DEFB $CB,$D0,$DA,$8D,$08,$80,$E8,$0B
  DEFB $1A,$78,$00,$37,$D6,$A2,$68,$D4
  DEFB $E8,$D9,$C8,$D6,$7D,$0D,$8D,$57
  DEFB $09,$B6,$66,$BE,$63,$57,$81,$D6
  DEFB $76,$6E,$63,$8C,$F4,$D6,$78,$D5
  DEFB $48,$09,$10,$0E,$80,$81,$03,$D7
  DEFB $88,$29,$06,$D9,$C8,$3B,$80,$91
  DEFB $01,$E0,$E8,$08,$12,$78,$00,$38
  DEFB $10,$D2,$26,$48,$D9,$C8,$15,$85
  DEFB $D1,$BA,$83,$A8,$04,$80,$91,$03
  DEFB $D8,$0B,$DB,$2D,$FD,$8D,$10,$A8
  DEFB $50,$58,$84,$B5,$8D,$BE,$80,$A0
  DEFB $BD,$AA,$78,$80,$1A,$51,$58,$5B
  DEFB $5D,$83,$28,$D0,$8A,$8C,$A8,$01
  DEFB $CB,$D0,$D8,$11,$C8,$78,$00,$37
  DEFB $05,$01,$50,$5B,$0B,$4D,$DA,$F2
  DEFB $68,$17,$82,$2D,$8D,$84,$D9,$4C
  DEFB $58,$5B,$80,$B0,$1D,$E5,$8D,$38
  DEFB $66,$E5,$A6,$48,$13,$8C,$18,$DA
  DEFB $B8,$D0,$99,$5B,$2B,$CF,$80,$91
  DEFB $05,$0C,$46,$77,$88,$C3,$83,$A8
  DEFB $06,$D9,$C8,$D4,$1D,$8E,$26,$8D
  DEFB $3F,$81,$38,$D4,$1D,$63,$A8,$10
  DEFB $D6,$7D,$0D,$8D,$CA,$56,$26,$81
  DEFB $01,$18,$3B,$78,$80,$1D,$D8,$60
  DEFB $51,$02,$D9,$18,$DA,$F5,$F5,$25
  DEFB $D2,$68,$15,$8D,$08,$A8,$0E,$78
  DEFB $00,$3A,$70,$5B,$98,$D6,$91,$02
  DEFB $3A,$8D,$57,$09,$D9,$C8,$3B,$80
  DEFB $91,$0E,$1E,$8E,$3F,$78,$00,$37
  DEFB $D6,$90,$1D,$E0,$66,$6C,$64,$8D
  DEFB $03,$67,$8D,$10,$D0,$D6,$48,$D5
  DEFB $70,$90,$1D,$20,$8D,$41,$D6,$32
  DEFB $68,$10,$3D,$78,$00,$38,$01,$17
  DEFB $8D,$9E,$82,$1A,$8D,$4B,$8D,$AB
  DEFB $85,$9B,$DA,$F5,$D2,$BD,$23,$80
  DEFB $BD,$78,$56,$80,$9B,$4B,$A5,$85
  DEFB $B4,$B8,$DA,$68,$55,$D0,$A8,$13
  DEFB $84,$FD,$A6,$A8,$5E,$59,$D6,$9D
  DEFB $BE,$95,$67,$28,$10,$60,$D0,$F8
  DEFB $17,$85,$B9,$95,$4A,$80,$8D,$9C
  DEFB $89,$5F,$52,$55,$8D,$9F,$4C,$97
  DEFB $88,$5E,$59,$D6,$9D,$7F,$98,$21
  DEFB $80,$60,$15,$65,$8A,$B5,$24,$C8
  DEFB $4D,$95,$95,$24,$C5,$D2,$68,$60
  DEFB $5B,$B5,$2D,$BE,$A8,$4D,$95,$F5
  DEFB $85,$E5,$B2,$68,$01,$4D,$62,$26
  DEFB $85,$6D,$9C,$70,$A8,$A5,$85,$E5
  DEFB $57,$8F,$00,$8F,$00,$38,$10,$17
  DEFB $80,$21,$0D,$66,$08,$10,$3F,$78
  DEFB $80,$70,$6B,$55,$56,$58,$A5,$D8
  DEFB $4B,$B5,$B9,$64,$8D,$F3,$80,$1D
  DEFB $13,$8D,$24,$8D,$8E,$A8,$D6,$91
  DEFB $01,$E8,$21,$78,$66,$E5,$08,$10
  DEFB $D2,$47,$0A,$8D,$E2,$80,$6A,$51
  DEFB $52,$56,$56,$95,$B2,$66,$48,$50
  DEFB $52,$5F,$26,$81,$05,$25,$6D,$DF
  DEFB $52,$D6,$90,$8C,$28,$4B,$92,$68
  DEFB $D6,$18,$75,$67,$00,$37,$05,$01
  DEFB $D0,$E3,$28,$13,$8D,$E4,$A8,$DE
  DEFB $03,$1D,$AA,$C8,$78,$80,$1A,$51
  DEFB $52,$56,$56,$95,$B2,$68,$DE,$28
  DEFB $D0,$8A,$80,$48,$D6,$C8,$01,$17
  DEFB $78,$00,$38,$01,$4F,$B5,$25,$B3
  DEFB $14,$BB,$5B,$5B,$DF,$D8,$A9,$5D
  DEFB $80,$8D,$C6,$17,$A7,$8F,$00,$8F
  DEFB $00,$37,$05,$01,$A5,$D5,$E4,$D6
  DEFB $26,$48,$29,$0C,$56,$D9,$C6,$28
  DEFB $5E,$A9,$D9,$18,$59,$B5,$99,$5B
  DEFB $A8,$0B,$A4,$C5,$B5,$85,$55,$5A
  DEFB $85,$56,$22,$68,$BC,$48,$0B,$05
  DEFB $4B,$58,$58,$54,$DC,$5A,$78,$00
  DEFB $37,$02,$01,$3C,$80,$51,$0D,$10
  DEFB $A8,$13,$8D,$6B,$A8,$0A,$09,$10
  DEFB $23,$A8,$09,$10,$1A,$80,$B0,$E7
  DEFB $8F,$00,$37,$05,$01,$D0,$55,$95
  DEFB $55,$EA,$51,$8D,$C6,$17,$64,$8D
  DEFB $37,$31,$10,$E4,$D5,$E5,$49,$70
  DEFB $A8,$58,$60,$57,$78,$89,$D6,$2D
  DEFB $BE,$26,$80,$50,$70,$65,$55,$E6
  DEFB $15,$E5,$B5,$25,$85,$EA,$64,$81
  DEFB $0D,$C6,$64,$84,$F5,$E5,$B5,$75
  DEFB $25,$D5,$E5,$B9,$80,$B5,$39,$D1
  DEFB $92,$BD,$24,$78,$66,$E5,$08,$10
  DEFB $D2,$48,$DE,$28,$06,$A5,$15,$25
  DEFB $65,$69,$5B,$26,$64,$85,$05,$25
  DEFB $F2,$68,$10,$52,$56,$DD,$F5,$2D
  DEFB $69,$08,$C2,$84,$B9,$26,$8D,$61
  DEFB $78,$67,$00,$38,$10,$D6,$60,$80
  DEFB $1D,$0E,$32,$82,$2D,$9C,$89,$61
  DEFB $5D,$5B,$95,$69,$31,$D0,$98,$5B
  DEFB $58,$58,$4F,$66,$E0,$11,$38,$C1
  DEFB $8D,$AB,$85,$95,$EA,$51,$2B,$DC
  DEFB $08,$09,$DE,$F8,$D9,$C8,$15,$67
  DEFB $78,$80,$1D,$71,$80,$81,$02,$18
  DEFB $12,$80,$65,$D5,$BD,$9C,$A5,$9B
  DEFB $5B,$DF,$D5,$D6,$48,$3A,$8D,$A2
  DEFB $85,$05,$88,$04,$8D,$6C,$81,$01
  DEFB $78,$D6,$91,$05,$8D,$9D,$8D,$0B
  DEFB $78,$00,$38,$10,$A5,$DD,$82,$A6
  DEFB $48,$D0,$61,$0D,$7F,$31,$58,$4C
  DEFB $4C,$5E,$59,$D9,$C5,$D8,$02,$D9
  DEFB $F5,$D8,$06,$01,$51,$B5,$54,$F8
  DEFB $4C,$D7,$FA,$5E,$56,$2B,$51,$B6
  DEFB $28,$4B,$B5,$59,$80,$5D,$7F,$98
  DEFB $2D,$66,$E4,$F8,$D5,$70,$91,$38
  DEFB $06,$01,$D5,$98,$D0,$F8,$05,$10
  DEFB $50,$C4,$67,$78,$00,$37,$05,$01
  DEFB $DE,$08,$32,$64,$8D,$72,$26,$8D
  DEFB $8F,$31,$D4,$E5,$0C,$47,$88,$01
  DEFB $D2,$D8,$DB,$6A,$81,$41,$E0,$E8
  DEFB $CA,$80,$1D,$27,$8A,$5A,$5E,$99
  DEFB $63,$98,$05,$10,$21,$78,$00,$37
  DEFB $05,$01,$D7,$18,$08,$32,$81,$38
  DEFB $C1,$8D,$AB,$8D,$2E,$2B,$03,$D2
  DEFB $6A,$84,$FD,$A6,$DF,$D8,$16,$10
  DEFB $D5,$12,$67,$86,$6E,$51,$8D,$9C
  DEFB $8D,$6F,$A5,$2D,$69,$C1,$85,$59
  DEFB $4F,$5D,$80,$1D,$27,$8D,$04,$80
  DEFB $21,$0D,$66,$08,$10,$D5,$A8,$13
  DEFB $83,$A8,$A5,$1D,$DE,$84,$B9,$8D
  DEFB $82,$80,$9A,$5A,$5E,$99,$63,$98
  DEFB $CA,$78,$67,$00,$37,$05,$01,$D2
  DEFB $78,$D0,$48,$D0,$82,$68,$0E,$C8
  DEFB $8C,$A8,$10,$D2,$86,$48,$0B,$14
  DEFB $09,$01,$D7,$18,$08,$32,$8D,$7A
  DEFB $82,$2D,$28,$78,$00,$37,$05,$01
  DEFB $60,$52,$4D,$98,$D7,$18,$08,$01
  DEFB $D0,$48,$CA,$81,$0D,$28,$8D,$56
  DEFB $07,$D2,$DA,$80,$91,$01,$18,$0B
  DEFB $1E,$11,$78,$80,$15,$95,$25,$59
  DEFB $80,$8D,$28,$8D,$08,$A8,$14,$D6
  DEFB $C8,$D9,$C5,$8D,$9D,$83,$27,$88
  DEFB $29,$06,$01,$5B,$2B,$D3,$D8,$59
  DEFB $BD,$AF,$5D,$2B,$D6,$91,$02,$18
  DEFB $12,$64,$80,$70,$60,$80,$14,$F5
  DEFB $2A,$51,$78,$00,$37,$05,$01,$D1
  DEFB $B8,$4F,$5E,$55,$55,$80,$8D,$28
  DEFB $81,$60,$14,$C5,$85,$55,$5B,$59
  DEFB $A2,$B3,$2D,$0D,$78,$66,$E5,$18
  DEFB $29,$06,$01,$D0,$46,$48,$13,$8C
  DEFB $18,$DA,$B8,$D3,$72,$B0,$3D,$9C
  DEFB $8D,$6F,$A5,$2D,$7F,$64,$8D,$08
  DEFB $26,$80,$48,$16,$CF,$80,$91,$0D
  DEFB $51,$26,$78,$67,$00,$38,$01,$D0
  DEFB $96,$48,$1A,$6B,$1E,$83,$28,$22
  DEFB $01,$5D,$52,$4D,$98,$56,$B5,$B5
  DEFB $48,$08,$4D,$52,$5B,$5D,$78,$80
  DEFB $12,$78,$D0,$F8,$D0,$8A,$80,$AC
  DEFB $A8,$10,$0E,$82,$17,$8F,$00,$37
  DEFB $D6,$91,$01,$18,$D7,$70,$8D,$9C
  DEFB $8D,$4E,$50,$C4,$8C,$E8,$58,$4C
  DEFB $4C,$5E,$59,$62,$26,$80,$1D,$E5
  DEFB $8D,$1B,$5B,$57,$78,$80,$13,$28
  DEFB $15,$A8,$CA,$80,$1D,$04,$80,$91
  DEFB $01,$A7,$8F,$00,$37,$36,$26,$8D
  DEFB $69,$10,$CE,$85,$79,$B5,$B8,$01
  DEFB $D7,$70,$91,$01,$16,$48,$D6,$32
  DEFB $68,$0E,$C8,$64,$8D,$9C,$8D,$2A
  DEFB $83,$48,$4B,$98,$D7,$85,$78,$A5
  DEFB $E5,$BC,$42,$B0,$30,$D7,$88,$29
  DEFB $06,$D9,$C8,$D2,$B8,$09,$10,$1E
  DEFB $78,$00,$38,$10,$3B,$80,$9D,$9C
  DEFB $8D,$2B,$80,$91,$01,$E7,$88,$09
  DEFB $10,$1A,$64,$83,$A8,$34,$8D,$78
  DEFB $8D,$9C,$8D,$2A,$8A,$5E,$5B,$C4
  DEFB $2B,$03,$01,$21,$80,$80,$D7,$8F
  DEFB $00,$37,$36,$26,$8C,$A8,$10,$0D
  DEFB $80,$81,$0C,$E6,$66,$C6,$48,$10
  DEFB $D3,$B8,$06,$DA,$F5,$DD,$FD,$A9
  DEFB $64,$8D,$06,$10,$DB,$38,$DA,$9A
  DEFB $83,$A8,$16,$DB,$E9,$52,$5B,$8D
  DEFB $43,$67,$78,$8D,$9C,$8D,$2A,$80
  DEFB $61,$E0,$E8,$16,$12,$78,$00,$37
  DEFB $36,$26,$8C,$A8,$10,$0D,$80,$81
  DEFB $0C,$E8,$5D,$58,$C8,$A8,$D9,$C8
  DEFB $D2,$A8,$09,$10,$1A,$66,$6C,$64
  DEFB $8D,$CE,$81,$0D,$3B,$80,$6D,$AF
  DEFB $5D,$DF,$DA,$96,$48,$10,$DB,$38
  DEFB $DA,$9A,$83,$A8,$16,$DB,$E9,$52
  DEFB $5B,$8D,$43,$67,$78,$00,$37,$36
  DEFB $26,$8C,$A8,$10,$0D,$80,$81,$0C
  DEFB $E6,$67,$16,$48,$D0,$61,$0D,$B3
  DEFB $8D,$A9,$A8,$3A,$81,$6D,$BE,$95
  DEFB $66,$77,$88,$D9,$C8,$D2,$A8,$06
  DEFB $DE,$18,$CA,$81,$0F,$0D,$80,$91
  DEFB $01,$E1,$18,$0B,$3A,$8D,$A2,$8D
  DEFB $F3,$8C,$58,$01,$27,$8D,$1B,$80
  DEFB $91,$01,$A0,$E7,$8F,$00,$37,$D5
  DEFB $70,$90,$12,$76,$48,$C4,$8D,$2A
  DEFB $80,$51,$0D,$9B,$80,$81,$0C,$E6
  DEFB $48,$10,$B5,$25,$B8,$06,$DF,$F3
  DEFB $14,$C5,$85,$85,$58,$12,$78,$00
  DEFB $37,$36,$26,$8D,$69,$10,$CE,$80
  DEFB $B3,$48,$D7,$B8,$10,$DB,$48,$08
  DEFB $5B,$5E,$A5,$12,$68,$D0,$20,$91
  DEFB $0F,$0E,$78,$80,$12,$18,$08,$0D
  DEFB $80,$61,$A8,$0B,$D3,$78,$D0,$21
  DEFB $1C,$87,$8F,$00,$37,$05,$01,$57
  DEFB $1C,$8D,$71,$8D,$56,$10,$CE,$84
  DEFB $B9,$D4,$AA,$80,$1D,$8F,$8D,$2C
  DEFB $4B,$5E,$4B,$4B,$55,$26,$81,$45
  DEFB $9B,$A5,$D8,$01,$4B,$B6,$28,$5D
  DEFB $58,$C8,$80,$1D,$50,$80,$51,$0D
  DEFB $1B,$5B,$57,$82,$17,$88,$10,$D7
  DEFB $E4,$C5,$E5,$B5,$BD,$FD,$5D,$8D
  DEFB $87,$A8,$3A,$85,$75,$88,$4C,$51
  DEFB $58,$52,$4C,$98,$D0,$60,$9D,$96
  DEFB $8D,$AA,$A5,$D5,$B9,$B5,$67,$8F
  DEFB $00,$37,$D6,$91,$0D,$A1,$80,$80
  DEFB $1D,$26,$62,$84,$BB,$62,$64,$80
  DEFB $1A,$51,$DA,$65,$86,$08,$DE,$48
  DEFB $D0,$8A,$80,$A1,$1C,$88,$D6,$C8
  DEFB $01,$D5,$98,$32,$78,$00,$37,$36
  DEFB $26,$8D,$69,$10,$CE,$64,$80,$12
  DEFB $18,$08,$0D,$85,$55,$85,$85,$6A
  DEFB $80,$91,$01,$A8,$0B,$D9,$C8,$3B
  DEFB $80,$9D,$9C,$8D,$2B,$80,$61,$E1
  DEFB $17,$88,$01,$4F,$BD,$AF,$5D,$85
  DEFB $B5,$EA,$51,$26,$83,$48,$4B,$98
  DEFB $D7,$B4,$D8,$16,$0E,$80,$81,$27
  DEFB $8F,$00,$38,$10,$DA,$18,$08,$D9
  DEFB $C8,$D2,$B8,$09,$10,$1A,$80,$81
  DEFB $38,$01,$CE,$8D,$68,$5B,$A8,$10
  DEFB $24,$80,$80,$1D,$E5,$8D,$1B,$5B
  DEFB $57,$78,$82,$90,$CD,$8B,$84,$CB
  DEFB $5B,$5F,$2B,$D6,$C8,$10,$1E,$82
  DEFB $18,$D0,$82,$68,$0A,$09,$01,$DF
  DEFB $E7,$8F,$00,$8F,$00,$37,$60,$B5
  DEFB $55,$42,$68,$0A,$01,$57,$1C,$8D
  DEFB $FE,$8B,$D1,$28,$10,$1E,$8D,$0B
  DEFB $80,$80,$1D,$E5,$8D,$1B,$5B,$57
  DEFB $78,$80,$1C,$E8,$4F,$D9,$2A,$81
  DEFB $02,$48,$08,$10,$D1,$B5,$B5,$78
  DEFB $D9,$C4,$D6,$48,$05,$10,$D7,$36
  DEFB $48,$D9,$C8,$D2,$A8,$06,$DE,$18
  DEFB $CA,$80,$12,$18,$08,$0D,$8A,$5E
  DEFB $5B,$C4,$26,$85,$25,$D7,$88,$D8
  DEFB $B8,$4C,$B5,$B5,$F2,$B0,$51,$02
  DEFB $18,$D0,$88,$14,$01,$27,$8D,$2B
  DEFB $78,$00,$8F,$00,$8F,$00,$8F,$00
  DEFB $37,$05,$01,$DE,$08,$D0,$E3,$27
  DEFB $8F,$00,$8F,$00,$38,$01,$4D,$19
  DEFB $1A,$73,$1E,$83,$28,$13,$8D,$2D
  DEFB $A8,$09,$10,$1E,$0E,$78,$00,$37
  DEFB $05,$D1,$78,$08,$D8,$98,$D1,$C8
  DEFB $CB,$66,$E5,$26,$48,$D6,$A2,$68
  DEFB $1D,$86,$05,$24,$D9,$8D,$C8,$8D
  DEFB $CA,$83,$A8,$09,$50,$95,$D8,$CA
  DEFB $67,$78,$00,$37,$02,$10,$11,$8C
  DEFB $D8,$08,$01,$D0,$5D,$12,$64,$8A
  DEFB $5D,$BD,$0A,$83,$26,$48,$13,$8D
  DEFB $E6,$DA,$F5,$E9,$A8,$0E,$C8,$80
  DEFB $BD,$2D,$A8,$DE,$03,$1D,$AA,$78
  DEFB $00,$37,$02,$01,$D5,$F2,$68,$08
  DEFB $01,$D0,$5D,$12,$80,$E6,$B1,$18
  DEFB $32,$80,$B0,$1A,$55,$58,$59,$26
  DEFB $8D,$A4,$81,$61,$01,$E8,$13,$84
  DEFB $C5,$E5,$B5,$F9,$A8,$D8,$F3,$10
  DEFB $A1,$A1,$17,$8F,$00,$37,$05,$01
  DEFB $D7,$18,$08,$32,$D0,$D8,$D2,$E2
  DEFB $B0,$30,$1D,$E5,$85,$95,$25,$59
  DEFB $80,$8D,$28,$66,$E5,$16,$48,$02
  DEFB $10,$D6,$60,$6D,$9C,$83,$B8,$3A
  DEFB $8D,$A2,$8D,$A3,$62,$8A,$4C,$5B
  DEFB $B5,$64,$B5,$59,$80,$A5,$D5,$86
  DEFB $77,$8F,$00,$37,$36,$26,$8D,$69
  DEFB $10,$CE,$8D,$56,$01,$D2,$C4,$CB
  DEFB $A4,$CB,$4D,$9A,$80,$51,$60,$1D
  DEFB $59,$8D,$04,$78,$80,$9C,$58,$10
  DEFB $CE,$80,$91,$01,$E8,$58,$5B,$81
  DEFB $E0,$E6,$48,$3A,$86,$0D,$DE,$8D
  DEFB $4B,$80,$93,$68,$CA,$80,$12,$18
  DEFB $08,$0D,$78,$80,$1D,$3A,$85,$55
  DEFB $29,$A8,$09,$10,$1A,$78,$00,$37
  DEFB $60,$B5,$55,$42,$68,$BD,$12,$80
  DEFB $1D,$FE,$8D,$69,$10,$1A,$8D,$0B
  DEFB $82,$18,$08,$01,$DE,$58,$D1,$B5
  DEFB $B5,$78,$13,$84,$C5,$E5,$B5,$F9
  DEFB $A8,$C4,$81,$61,$18,$09,$10,$1E
  DEFB $0E,$64,$80,$1C,$E8,$D6,$85,$BA
  DEFB $81,$02,$48,$0B,$D9,$C8,$D2,$A6
  DEFB $48,$A5,$E5,$BC,$42,$B0,$30,$D8
  DEFB $06,$DE,$18,$05,$10,$D9,$B7,$88
  DEFB $4F,$B5,$B8,$C7,$09,$10,$11,$83
  DEFB $A8,$34,$8D,$78,$8D,$56,$01,$D2
  DEFB $CC,$5A,$81,$0C,$E8,$16,$01,$D5
  DEFB $98,$D0,$47,$88,$29,$06,$01,$D7
  DEFB $D8,$DE,$3D,$69,$10,$21,$78,$00
  DEFB $38,$01,$3C,$80,$80,$1D,$09,$8D
  DEFB $A4,$80,$91,$0F,$0E,$80,$B0,$1D
  DEFB $7C,$5B,$83,$28,$D0,$82,$68,$14
  DEFB $16,$10,$1A,$8D,$FE,$80,$91,$01
  DEFB $A1,$17,$8F,$00,$37,$05,$10,$DC
  DEFB $48,$17,$64,$82,$90,$C5,$BB,$4C
  DEFB $54,$A8,$DC,$A8,$DA,$68,$56,$D9
  DEFB $C5,$79,$5B,$80,$82,$8A,$64,$8A
  DEFB $B4,$B5,$B9,$A8,$0B,$54,$57,$52
  DEFB $5F,$9A,$8B,$C4,$81,$02,$1A,$78
  DEFB $8D,$0F,$A8,$D0,$88,$D8,$80,$5D
  DEFB $A6,$8D,$A5,$A8,$0B,$01,$DB,$18
  DEFB $50,$58,$9A,$80,$AC,$A8,$10,$D5
  DEFB $12,$67,$8F,$00,$37,$05,$10,$4D
  DEFB $5E,$B5,$58,$17,$64,$82,$90,$C5
  DEFB $BB,$4C,$54,$A8,$DC,$A8,$DA,$68
  DEFB $56,$D9,$C5,$79,$5B,$80,$82,$8A
  DEFB $64,$8A,$B4,$B5,$B9,$A8,$0B,$54
  DEFB $57,$52,$5F,$9A,$8B,$C4,$81,$02
  DEFB $1A,$78,$8D,$0F,$A8,$D0,$88,$D8
  DEFB $80,$5D,$A6,$8D,$A5,$A8,$0B,$01
  DEFB $DB,$18,$50,$58,$9A,$80,$AC,$A8
  DEFB $10,$D5,$12,$67,$8F,$00,$38,$01
  DEFB $27,$8D,$01,$17,$81,$38,$06,$4F
  DEFB $9B,$5D,$5E,$5B,$9D,$91,$8D,$06
  DEFB $DC,$A8,$01,$1F,$8D,$47,$4D,$8D
  DEFB $AF,$4D,$DF,$D5,$DB,$DA,$D8,$05
  DEFB $10,$21,$78,$80,$1D,$B1,$8D,$C0
  DEFB $81,$40,$61,$0D,$7F,$31,$15,$78
  DEFB $00,$8F,$00,$38,$01,$DE,$88,$21
  DEFB $2B,$D9,$98,$22,$D7,$F9,$81,$58
  DEFB $09,$10,$1A,$78,$00,$38,$01,$3C
  DEFB $80,$83,$2A,$64,$8D,$7F,$98,$D0
  DEFB $82,$68,$0A,$1A,$11,$64,$81,$05
  DEFB $8D,$9D,$8D,$8F,$31,$DA,$A7,$88
  DEFB $29,$06,$D3,$68,$B5,$25,$B8,$4C
  DEFB $58,$56,$26,$80,$A1,$61,$01,$A7
  DEFB $8F,$00,$37,$05,$01,$D3,$68,$0E
  DEFB $6B,$11,$83,$27,$8F,$00,$37,$05
  DEFB $01,$60,$95,$D8,$32,$D0,$D8,$04
  DEFB $D0,$B8,$01,$CB,$D0,$D6,$48,$29
  DEFB $06,$01,$D8,$98,$5B,$58,$B5,$B2
  DEFB $68,$DB,$48,$4C,$58,$56,$26,$81
  DEFB $41,$61,$01,$17,$8F,$00,$37,$05
  DEFB $60,$51,$02,$60,$BA,$8D,$7F,$4C
  DEFB $98,$01,$D0,$55,$05,$B0,$B1,$78
  DEFB $D0,$65,$75,$86,$08,$D6,$3A,$8D
  DEFB $15,$80,$B4,$D9,$4C,$B6,$29,$4D
  DEFB $64,$80,$21,$01,$A8,$CD,$83,$A8
  DEFB $34,$8D,$78,$80,$12,$5D,$33,$81
  DEFB $38,$C6,$A8,$09,$4B,$98,$58,$4C
  DEFB $4C,$5E,$59,$52,$94,$D7,$8F,$00
  DEFB $8F,$00,$37,$D6,$91,$0D,$77,$08
  DEFB $01,$D8,$F8,$D2,$F7,$88,$D6,$32
  DEFB $68,$5E,$59,$64,$83,$A8,$34,$8D
  DEFB $78,$80,$1D,$76,$4F,$DA,$68,$4F
  DEFB $DA,$62,$68,$16,$01,$A5,$85,$E5
  DEFB $B4,$C9,$80,$85,$5D,$0A,$84,$FB
  DEFB $5B,$8C,$37,$86,$6E,$57,$8D,$D8
  DEFB $DB,$E2,$68,$C1,$84,$CB,$5E,$A2
  DEFB $B1,$0D,$2C,$09,$AD,$19,$80,$90
  DEFB $1A,$5D,$B5,$D9,$8D,$56,$07,$06
  DEFB $52,$56,$DA,$79,$80,$95,$D5,$BB
  DEFB $5F,$95,$BA,$97,$86,$7F,$00,$38
  DEFB $10,$1E,$0F,$CD,$80,$80,$1D,$59
  DEFB $8D,$32,$78,$8D,$88,$09,$D7,$F9
  DEFB $8D,$0B,$80,$1D,$31,$80,$6D,$46
  DEFB $57,$8D,$69,$10,$24,$78,$66,$E5
  DEFB $38,$BA,$83,$A8,$C5,$94,$D6,$48
  DEFB $01,$56,$D9,$C8,$05,$01,$D2,$38
  DEFB $5B,$58,$4B,$98,$02,$10,$58,$D9
  DEFB $D8,$CD,$8D,$F3,$84,$FD,$AF,$52
  DEFB $A5,$19,$A8,$56,$5E,$5D,$5D,$95
  DEFB $B2,$68,$DD,$8D,$BE,$26,$8B,$4B
  DEFB $04,$80,$1A,$5E,$56,$56,$D7,$F2
  DEFB $68,$4B,$9D,$CA,$98,$D6,$32,$68
  DEFB $02,$3A,$82,$2D,$9C,$89,$5F,$52
  DEFB $55,$85,$05,$B0,$50,$B4,$D5,$2A
  DEFB $C6,$26,$78,$67,$80,$13,$38,$D0
  DEFB $8A,$81,$A0,$E8,$0B,$01,$25,$32
  DEFB $64,$81,$E0,$E7,$8F,$00,$37,$02
  DEFB $10,$1A,$0F,$CD,$80,$80,$1D,$32
  DEFB $78,$80,$15,$71,$C8,$D5,$08,$05
  DEFB $10,$11,$82,$18,$06,$10,$D7,$F3
  DEFB $11,$57,$8F,$00,$37,$DA,$FD,$0B
  DEFB $80,$1D,$31,$8D,$46,$57,$8D,$69
  DEFB $10,$D3,$28,$24,$78,$00,$37,$02
  DEFB $10,$0E,$8C,$D8,$08,$01,$D1,$28
  DEFB $33,$8D,$E6,$BD,$AF,$26,$85,$6D
  DEFB $9C,$62,$8D,$A8,$A6,$6E,$62,$64
  DEFB $8D,$7F,$98,$C6,$A8,$09,$4B,$98
  DEFB $1D,$67,$78,$80,$1D,$04,$8C,$5A
  DEFB $80,$21,$0F,$0E,$8C,$D7,$8F,$00
  DEFB $37,$02,$10,$11,$8C,$D8,$08,$01
  DEFB $D1,$28,$33,$82,$25,$6D,$9C,$62
  DEFB $8D,$0C,$2B,$DA,$8A,$8B,$D1,$28
  DEFB $52,$5D,$78,$81,$03,$38,$DE,$6D
  DEFB $AF,$5E,$9A,$81,$18,$0B,$01,$4D
  DEFB $52,$56,$83,$28,$D0,$8A,$81,$E1
  DEFB $17,$8F,$00,$37,$02,$10,$57,$1C
  DEFB $8C,$D8,$08,$01,$DE,$58,$D1,$B5
  DEFB $B5,$78,$D9,$E8,$96,$15,$9D,$9C
  DEFB $A9,$8D,$FB,$9A,$84,$FB,$5B,$8B
  DEFB $D0,$D8,$11,$C8,$78,$00,$38,$01
  DEFB $D4,$D1,$76,$48,$BD,$F5,$81,$6D
  DEFB $9C,$8D,$FD,$58,$5B,$56,$58,$5E
  DEFB $A8,$D6,$7D,$0D,$80,$91,$0F,$0E
  DEFB $64,$81,$0D,$7F,$31,$15,$80,$64
  DEFB $FB,$5B,$8C,$38,$3A,$81,$38,$D7
  DEFB $F3,$10,$15,$05,$2D,$9C,$5D,$8D
  DEFB $A2,$8D,$A7,$62,$85,$BD,$9A,$75
  DEFB $00,$DB,$E0,$61,$78,$C1,$84,$C5
  DEFB $1B,$5B,$5B,$2B,$0B,$A5,$85,$85
  DEFB $D2,$B2,$1A,$64,$82,$2C,$BD,$0D
  DEFB $A8,$D0,$82,$68,$0E,$80,$B1,$17
  DEFB $88,$07,$06,$D0,$55,$15,$85,$D8
  DEFB $12,$80,$B3,$A8,$34,$8D,$78,$81
  DEFB $05,$B9,$BA,$D6,$96,$05,$16,$27
  DEFB $8F,$00,$37,$36,$26,$8D,$69,$01
  DEFB $D0,$5D,$8F,$8D,$2C,$0B,$56,$5E
  DEFB $A5,$D8,$D9,$68,$07,$DA,$A7,$8F
  DEFB $00,$37,$02,$10,$1A,$8C,$D8,$08
  DEFB $10,$D3,$38,$17,$64,$81,$04,$F5
  DEFB $25,$05,$E5,$B9,$8D,$69,$07,$06
  DEFB $01,$A5,$49,$55,$95,$DD,$7F,$66
  DEFB $E5,$97,$88,$10,$D3,$38,$C1,$85
  DEFB $B9,$4C,$DF,$D5,$D3,$1D,$AB,$85
  DEFB $65,$85,$F2,$B0,$9D,$EF,$8D,$8B
  DEFB $81,$40,$90,$1D,$59,$8D,$0E,$32
  DEFB $67,$78,$00,$37,$05,$01,$32,$64
  DEFB $81,$38,$D7,$4A,$8D,$8F,$31,$14
  DEFB $09,$10,$1A,$78,$00,$38,$10,$11
  DEFB $8D,$0B,$80,$80,$15,$71,$C6,$48
  DEFB $D0,$64,$D9,$95,$96,$48,$D3,$47
  DEFB $88,$29,$06,$01,$D2,$98,$BD,$5F
  DEFB $80,$71,$28,$0B,$01,$D5,$C8,$D9
  DEFB $6A,$81,$0D,$34,$8D,$CA,$80,$1D
  DEFB $CB,$98,$09,$10,$1E,$78,$00,$37
  DEFB $D6,$91,$0F,$0E,$8D,$0B,$80,$80
  DEFB $15,$71,$C8,$D3,$48,$D5,$60,$1D
  DEFB $29,$8D,$5F,$9A,$85,$25,$D6,$48
  DEFB $01,$32,$8D,$E6,$DA,$F5,$E9,$A8
  DEFB $0E,$81,$61,$27,$8F,$00,$37,$05
  DEFB $01,$D3,$58,$22,$4B,$58,$5D,$5D
  DEFB $55,$9A,$64,$85,$3B,$5B,$A8,$0B
  DEFB $5D,$9A,$5D,$85,$D5,$E4,$B9,$A8
  DEFB $D9,$58,$BD,$5F,$8D,$B2,$DF,$D8
  DEFB $4B,$DF,$D4,$C5,$19,$A7,$88,$10
  DEFB $B5,$D5,$65,$8A,$59,$12,$80,$51
  DEFB $28,$06,$D0,$55,$95,$E5,$75,$0D
  DEFB $FD,$5D,$8D,$06,$02,$10,$AB,$56
  DEFB $98,$DC,$F8,$07,$56,$1B,$A8,$3A
  DEFB $84,$F9,$95,$58,$A5,$59,$95,$96
  DEFB $27,$88,$01,$CB,$D0,$D8,$D0,$8A
  DEFB $8C,$A8,$09,$D9,$C5,$8D,$9D,$81
  DEFB $78,$09,$10,$0E,$78,$00,$37,$05
  DEFB $01,$D3,$68,$17,$82,$20,$1D,$99
  DEFB $80,$51,$0D,$73,$78,$81,$0D,$3B
  DEFB $8D,$78,$56,$A8,$09,$4B,$98,$4C
  DEFB $58,$56,$26,$81,$60,$11,$78,$09
  DEFB $10,$0E,$78,$66,$E5,$58,$29,$06
  DEFB $01,$4B,$5B,$99,$63,$98,$4B,$D0
  DEFB $92,$68,$CA,$81,$27,$86,$7F,$00
  DEFB $37,$05,$01,$D9,$98,$22,$D0,$FA
  DEFB $8D,$88,$1A,$80,$B0,$E7,$86,$6E
  DEFB $55,$82,$90,$60,$1D,$89,$8D,$74
  DEFB $84,$BD,$09,$26,$8C,$A8,$09,$10
  DEFB $0E,$78,$67,$00,$37,$02,$10,$D1
  DEFB $A8,$08,$01,$5F,$95,$B5,$D5,$24
  DEFB $CB,$55,$8D,$E9,$66,$E5,$58,$D0
  DEFB $82,$68,$0A,$09,$01,$A5,$85,$E5
  DEFB $B4,$C9,$80,$85,$5D,$0A,$84,$FB
  DEFB $5B,$8C,$37,$88,$01,$D8,$98,$D7
  DEFB $48,$06,$60,$51,$52,$A5,$D5,$52
  DEFB $68,$0A,$10,$DE,$96,$77,$8F,$00
  DEFB $38,$01,$27,$8D,$30,$D0,$38,$D1
  DEFB $B8,$D9,$95,$D2,$B2,$2D,$0F,$A8
  DEFB $0B,$D3,$EA,$78,$00,$37,$02,$01
  DEFB $D0,$5C,$98,$3C,$80,$8D,$30,$D0
  DEFB $38,$32,$A7,$8F,$00,$37,$05,$10
  DEFB $58,$5B,$4B,$81,$76,$48,$05,$10
  DEFB $2F,$D6,$AA,$80,$1D,$03,$8D,$CA
  DEFB $8D,$86,$26,$81,$05,$85,$B4,$B7
  DEFB $88,$D0,$38,$D8,$B8,$4C,$5E,$5D
  DEFB $8D,$6C,$81,$0D,$30,$D0,$38,$D0
  DEFB $88,$0A,$09,$10,$11,$00,$37,$05
  DEFB $01,$57,$1C,$8D,$04,$64,$82,$90
  DEFB $60,$16,$66,$BE,$55,$CF,$4D,$86
  DEFB $7D,$49,$8C,$B8,$12,$66,$E5,$58
  DEFB $22,$01,$D7,$D8,$4C,$B5,$B5,$F2
  DEFB $BD,$69,$52,$5D,$78,$80,$70,$66
  DEFB $05,$24,$D9,$81,$D8,$0B,$01,$D7
  DEFB $ED,$74,$80,$64,$BD,$09,$26,$81
  DEFB $40,$1D,$59,$64,$84,$D9,$95,$98
  DEFB $D0,$F6,$77,$88,$10,$D0,$48,$55
  DEFB $95,$F9,$55,$A8,$04,$8B,$A8,$07
  DEFB $DB,$6A,$81,$1C,$87,$8F,$00,$37
  DEFB $02,$10,$1F,$5D,$80,$80,$1D,$E0
  DEFB $85,$71,$C8,$D0,$47,$8F,$00,$37
  DEFB $05,$01,$D6,$86,$48,$29,$06,$01
  DEFB $4D,$99,$59,$64,$8D,$39,$8D,$3A
  DEFB $81,$38,$A5,$D5,$B9,$4C,$51,$9A
  DEFB $81,$EC,$87,$88,$DB,$E5,$B9,$98
  DEFB $32,$A8,$D0,$88,$0E,$C8,$64,$81
  DEFB $61,$01,$A0,$E8,$D7,$F9,$85,$F5
  DEFB $85,$24,$C9,$A8,$34,$84,$B9,$8D
  DEFB $7B,$4D,$64,$81,$01,$E0,$E8,$D7
  DEFB $F9,$80,$6A,$52,$55,$DF,$D5,$D8
  DEFB $0B,$10,$58,$D9,$D8,$D7,$4A,$8A
  DEFB $D0,$93,$15,$E5,$9C,$8A,$78,$00
  DEFB $38,$01,$D1,$B8,$D9,$F5,$D3,$1D
  DEFB $4E,$84,$CD,$7F,$A5,$D5,$B5,$E4
  DEFB $CD,$AD,$64,$8D,$E7,$8D,$78,$56
  DEFB $80,$94,$B9,$88,$60,$D9,$C4,$D9
  DEFB $5B,$26,$80,$50,$B0,$48,$08,$4B
  DEFB $58,$DB,$E8,$1A,$80,$B1,$E1,$18
  DEFB $15,$A7,$88,$29,$06,$01,$50,$5B
  DEFB $58,$0A,$08,$DE,$78,$DA,$E2,$68
  DEFB $02,$10,$0E,$8C,$D7,$8F,$00,$37
  DEFB $02,$10,$DA,$E4,$FB,$4C,$98,$08
  DEFB $10,$D1,$B6,$48,$29,$0C,$DD,$D8
  DEFB $DE,$78,$DA,$E2,$68,$12,$64,$85
  DEFB $25,$05,$75,$85,$B2,$68,$3A,$5B
  DEFB $8D,$9F,$4C,$97,$8F,$00,$37,$05
  DEFB $01,$D1,$56,$48,$4C,$58,$4B,$60
  DEFB $94,$BD,$C6,$8D,$0E,$32,$8D,$64
  DEFB $81,$0D,$33,$81,$77,$88,$07,$DB
  DEFB $6A,$8D,$6C,$81,$05,$05,$55,$85
  DEFB $85,$68,$09,$10,$11,$00,$37,$02
  DEFB $01,$D1,$18,$CD,$80,$51,$0D,$0E
  DEFB $32,$78,$66,$6B,$E5,$88,$01,$D0
  DEFB $F8,$05,$10,$1E,$82,$18,$C1,$8D
  DEFB $AB,$84,$B5,$B5,$24,$C5,$42,$B5
  DEFB $E5,$96,$76,$6E,$58,$82,$90,$60
  DEFB $1D,$0F,$8D,$08,$26,$81,$4C,$A8
  DEFB $CA,$81,$01,$E8,$21,$8D,$6C,$80
  DEFB $1D,$05,$25,$17,$78,$85,$24,$F8
  DEFB $3A,$8A,$4C,$5B,$B5,$64,$B5,$59
  DEFB $8D,$AA,$64,$83,$A8,$DA,$36,$28
  DEFB $60,$D7,$F7,$05,$D8,$4B,$98,$D8
  DEFB $28,$09,$50,$95,$D8,$DC,$08,$0A
  DEFB $B5,$0B,$DA,$F6,$77,$8F,$00,$37
  DEFB $05,$D8,$08,$35,$78,$00,$37,$05
  DEFB $D8,$08,$35,$78,$00,$37,$05,$01
  DEFB $D3,$72,$68,$04,$D0,$B8,$D9,$C8
  DEFB $D9,$C4,$C5,$2D,$FD,$5D,$8D,$C7
  DEFB $64,$85,$1B,$55,$4F,$84,$CD,$7F
  DEFB $4C,$9B,$55,$2B,$03,$5F,$DA,$F9
  DEFB $A8,$13,$8D,$68,$5B,$85,$25,$DA
  DEFB $8D,$50,$2B,$21,$A7,$8F,$00,$37
  DEFB $DA,$FD,$0B,$80,$1D,$F5,$52,$DA
  DEFB $66,$28,$5B,$5E,$DA,$F2,$BD,$C7
  DEFB $64,$8D,$7F,$31,$4C,$5B,$5E,$56
  DEFB $4B,$55,$26,$88,$21,$A8,$0C,$55
  DEFB $94,$F5,$D8,$08,$60,$51,$02,$60
  DEFB $BA,$8D,$7F,$4C,$98,$01,$D8,$D8
  DEFB $D1,$F2,$67,$8F,$00,$37,$05,$01
  DEFB $60,$DA,$F9,$8D,$A8,$B5,$B8,$55
  DEFB $07,$03,$4B,$55,$B6,$32,$68,$5D
  DEFB $58,$5B,$4C,$51,$9A,$84,$FB,$A5
  DEFB $DD,$FD,$2B,$09,$10,$1A,$80,$B1
  DEFB $E8,$21,$A7,$88,$DB,$2D,$FD,$8D
  DEFB $8B,$8D,$08,$80,$AD,$6C,$85,$5D
  DEFB $0A,$80,$B0,$1D,$59,$8C,$BD,$0D
  DEFB $80,$60,$51,$01,$18,$21,$78,$00
  DEFB $8F,$00,$37,$36,$26,$8D,$69,$01
  DEFB $D3,$98,$D3,$A6,$48,$D0,$2C,$5A
  DEFB $81,$0D,$68,$8C,$A8,$D9,$C8,$1D
  DEFB $26,$80,$91,$01,$E8,$0B,$29,$06
  DEFB $01,$D0,$72,$68,$02,$10,$1A,$8C
  DEFB $D7,$8F,$00,$37,$05,$01,$25,$A5
  DEFB $D5,$85,$B9,$81,$78,$C3,$81,$04
  DEFB $DD,$AF,$26,$81,$76,$48,$07,$DE
  DEFB $6B,$DA,$FA,$8C,$F4,$D8,$4B,$58
  DEFB $61,$9A,$80,$84,$F5,$85,$84,$D6
  DEFB $6E,$A6,$48,$01,$4C,$58,$52,$55
  DEFB $80,$8D,$B0,$67,$80,$BD,$88,$09
  DEFB $D7,$F9,$8D,$0B,$64,$80,$16,$0D
  DEFB $AF,$4C,$51,$82,$20,$15,$D5,$E5
  DEFB $B5,$72,$68,$DD,$B7,$88,$5B,$52
  DEFB $4C,$54,$95,$D6,$28,$D1,$0A,$80
  DEFB $C1,$0D,$7F,$31,$D0,$D8,$DC,$08
  DEFB $DA,$A7,$8F,$00,$37,$A6,$02,$62
  DEFB $68,$D6,$91,$0D,$38,$85,$D5,$8C
  DEFB $88,$10,$D3,$F7,$5F,$00,$37,$05
  DEFB $10,$D3,$F8,$C3,$81,$04,$DD,$AF
  DEFB $26,$81,$76,$48,$10,$DB,$18,$14
  DEFB $C1,$8D,$AB,$85,$B9,$56,$58,$5F
  DEFB $2B,$0B,$07,$06,$DF,$98,$51,$52
  DEFB $50,$51,$80,$9D,$C9,$78,$00,$37
  DEFB $05,$FF,$01,$25,$17,$8D,$E6,$BD
  DEFB $AF,$26,$8B,$4B,$04,$84,$44,$78
  DEFB $DB,$2D,$FD,$8D,$C6,$A7,$88,$D8
  DEFB $B8,$D0,$88,$DC,$08,$14,$16,$DB
  DEFB $E0,$6C,$D8,$0B,$01,$CB,$D0,$D8
  DEFB $D0,$8A,$8D,$7F,$09,$10,$23,$A8
  DEFB $16,$10,$1E,$0F,$CD,$78,$00,$8F
  DEFB $00,$37,$02,$10,$CD,$80,$81,$01
  DEFB $10,$F2,$38,$57,$9B,$5B,$8D,$9C
  DEFB $83,$B8,$09,$10,$E1,$E8,$E3,$F8
  DEFB $D5,$62,$90,$C5,$6D,$9C,$62,$84
  DEFB $CB,$50,$9A,$85,$15,$85,$EA,$26
  DEFB $84,$B5,$25,$B4,$DA,$80,$8D,$A6
  DEFB $8D,$47,$A8,$0B,$A5,$26,$39,$A7
  DEFB $8F,$00,$38,$10,$E5,$6B,$5B,$DA
  DEFB $F9,$5B,$70,$A8,$17,$64,$8D,$88
  DEFB $01,$1A,$11,$80,$91,$E0,$E8,$32
  DEFB $78,$82,$90,$CD,$C5,$A8,$08,$A5
  DEFB $D5,$E4,$F4,$F2,$B4,$F5,$2A,$51
  DEFB $64,$83,$62,$68,$D1,$E8,$0B,$58
  DEFB $D9,$D8,$A9,$01,$5B,$95,$55,$24
  DEFB $CA,$8D,$69,$4D,$52,$A5,$95,$5B
  DEFB $62,$78,$81,$0D,$9B,$73,$59,$52
  DEFB $94,$C9,$80,$60,$14,$B5,$25,$08
  DEFB $DB,$2D,$FD,$83,$62,$68,$DB,$37
  DEFB $8F,$00,$37,$02,$10,$11,$8C,$D8
  DEFB $08,$01,$D9,$78,$33,$66,$E5,$B6
  DEFB $48,$29,$06,$01,$DF,$F8,$DB,$48
  DEFB $4C,$58,$56,$26,$81,$64,$F5,$E5
  DEFB $BD,$9D,$8B,$D1,$28,$52,$5D,$67
  DEFB $78,$00,$10,$D9,$78,$33,$8D,$B6
  DEFB $A8,$0E,$85,$85,$B8,$11,$66,$E5
  DEFB $B6,$48,$29,$06,$01,$A5,$15,$E4
  DEFB $F4,$F5,$52,$68,$DB,$48,$4C,$58
  DEFB $56,$26,$81,$6D,$75,$8C,$F8,$4B
  DEFB $62,$64,$8D,$06,$52,$5D,$A8,$A5
  DEFB $85,$E5,$B4,$C9,$80,$6C,$28,$DE
  DEFB $16,$77,$8F,$00,$37,$05,$D9,$C8
  DEFB $D0,$55,$71,$C8,$0E,$6B,$11,$83
  DEFB $36,$48,$D5,$70,$90,$12,$78,$CB
  DEFB $D0,$D7,$8F,$00,$37,$05,$01,$17
  DEFB $82,$25,$D6,$05,$88,$4D,$52,$A5
  DEFB $DD,$AF,$4C,$5D,$31,$4D,$52,$4F
  DEFB $4F,$95,$BD,$FD,$5D,$85,$1B,$55
  DEFB $5F,$9A,$78,$8D,$BE,$06,$CD,$8C
  DEFB $18,$01,$DE,$88,$24,$80,$BD,$51
  DEFB $26,$8D,$CB,$A5,$D8,$10,$1E,$8C
  DEFB $D8,$06,$DF,$38,$57,$58,$5B,$56
  DEFB $B5,$58,$D2,$67,$88,$29,$06,$01
  DEFB $D5,$08,$5B,$5E,$57,$57,$26,$8B
  DEFB $C4,$81,$02,$1A,$80,$BD,$51,$26
  DEFB $85,$79,$B5,$B8,$DB,$E0,$6C,$D7
  DEFB $8F,$00,$37,$02,$10,$1E,$8C,$D8
  DEFB $08,$10,$D3,$C8,$17,$78,$00,$37
  DEFB $05,$01,$D1,$B8,$22,$01,$57,$1C
  DEFB $8D,$3E,$85,$B5,$E5,$75,$72,$68
  DEFB $10,$55,$DF,$D5,$0D,$BE,$80,$81
  DEFB $02,$47,$8F,$00,$37,$02,$01,$D1
  DEFB $18,$CD,$64,$81,$0D,$3E,$84,$B9
  DEFB $D4,$AA,$80,$15,$1B,$52,$5B,$55
  DEFB $DA,$F9,$8D,$50,$80,$BD,$B5,$8D
  DEFB $6C,$81,$02,$17,$8F,$00,$68,$37
  DEFB $05,$01,$D0,$5D,$27,$80,$E6,$B1
  DEFB $18,$32,$66,$E5,$B6,$48,$29,$06
  DEFB $01,$A5,$15,$E4,$F4,$F5,$52,$68
  DEFB $57,$58,$52,$A9,$84,$C5,$85,$62
  DEFB $68,$16,$D7,$58,$CF,$67,$78,$00
  DEFB $37,$D5,$70,$90,$1D,$FF,$86,$AE
  DEFB $56,$6A,$8D,$47,$4D,$83,$B7,$88
  DEFB $01,$32,$8D,$B5,$81,$E1,$18,$16
  DEFB $12,$78,$00,$37,$D5,$70,$90,$1D
  DEFB $FF,$86,$AE,$56,$6A,$8D,$47,$4D
  DEFB $83,$B7,$88,$01,$32,$8D,$B5,$81
  DEFB $A1,$18,$16,$12,$78,$00,$2A,$61
  DEFB $00,$2A,$61,$00,$2A,$61,$00,$2A
  DEFB $61,$00,$2A,$61,$00,$2A,$61,$00
  DEFB $2A,$61,$00,$2A,$61,$00,$2A,$61
  DEFB $00,$2A,$61,$00,$2A,$61,$00,$2A
  DEFB $61,$00,$8F,$00,$38,$01,$56,$5E
  DEFB $A5,$D6,$28,$DB,$82,$66,$48,$57
  DEFB $95,$05,$59,$4C,$5D,$2B,$D3,$F6
  DEFB $48,$13,$85,$2A,$66,$5E,$8B,$55
  DEFB $56,$58,$A5,$D6,$78,$DB,$F8,$57
  DEFB $58,$60,$78,$00,$38,$01,$D2,$D8
  DEFB $05,$01,$4C,$5E,$5B,$5F,$26,$81
  DEFB $A6,$B1,$E8,$32,$64,$82,$2D,$9C
  DEFB $58,$D9,$D8,$DB,$62,$68,$0A,$09
  DEFB $10,$1A,$11,$78,$00,$37,$D6,$91
  DEFB $0D,$98,$80,$80,$1D,$E8,$82,$12
  DEFB $BD,$99,$64,$83,$A8,$DA,$28,$DD
  DEFB $48,$14,$D0,$65,$6D,$0A,$8C,$28
  DEFB $4B,$98,$D8,$28,$09,$50,$95,$D8
  DEFB $DC,$08,$5E,$59,$78,$00,$37,$05
  DEFB $01,$D0,$5D,$09,$8D,$1B,$8B,$56
  DEFB $D7,$F5,$0A,$5D,$85,$65,$E4,$C5
  DEFB $18,$4F,$55,$58,$5D,$AB,$56,$81
  DEFB $38,$C1,$8D,$AB,$8A,$60,$95,$95
  DEFB $D8,$05,$09,$DC,$A5,$68,$01,$D3
  DEFB $A8,$08,$58,$52,$31,$A5,$55,$E4
  DEFB $D5,$09,$78,$00,$37,$05,$D8,$08
  DEFB $35,$78,$00,$37,$04,$D0,$B8,$01
  DEFB $D0,$48,$D5,$70,$9D,$9C,$8D,$1C
  DEFB $8D,$B7,$97,$88,$29,$06,$01,$60
  DEFB $DA,$F4,$C5,$18,$D6,$91,$0D,$AF
  DEFB $D0,$B6,$66,$08,$D5,$70,$91,$38
  DEFB $D6,$AA,$80,$15,$62,$68,$5F,$BA
  DEFB $96,$76,$6E,$60,$64,$8D,$F6,$95
  DEFB $F9,$5B,$64,$81,$0D,$B7,$98,$06
  DEFB $D6,$D8,$1D,$67,$78,$80,$1D,$5C
  DEFB $8D,$B5,$81,$E0,$E8,$D6,$C8,$10
  DEFB $DB,$2A,$78,$00,$38,$01,$4B,$55
  DEFB $9B,$54,$8D,$A8,$64,$81,$0D,$7F
  DEFB $31,$4F,$9B,$5D,$5E,$5B,$98,$4B
  DEFB $92,$68,$01,$5D,$58,$5B,$4C,$51
  DEFB $84,$FB,$A5,$DD,$FD,$2B,$09,$10
  DEFB $1A,$82,$16,$6E,$61,$64,$8D,$57
  DEFB $09,$13,$80,$1D,$71,$80,$82,$18
  DEFB $C1,$8D,$AB,$81,$D9,$4D,$67,$66
  DEFB $6B,$E6,$27,$88,$10,$DA,$88,$CB
  DEFB $80,$6D,$0C,$94,$D6,$77,$8F,$00
  DEFB $37,$05,$01,$D0,$48,$DB,$62,$68
  DEFB $DE,$03,$10,$A0,$91,$0F,$0E,$78
  DEFB $00,$37,$DA,$FD,$0B,$80,$1D,$04
  DEFB $8D,$57,$09,$01,$60,$DA,$F4,$C5
  DEFB $18,$5E,$A2,$B0,$95,$85,$99,$5B
  DEFB $B5,$D9,$81,$0D,$B7,$98,$02,$10
  DEFB $3B,$78,$66,$E6,$08,$10,$DB,$79
  DEFB $80,$6D,$6D,$81,$D7,$86,$7F,$00
  DEFB $37,$D6,$91,$0D,$98,$80,$80,$1D
  DEFB $99,$81,$61,$38,$D9,$C8,$B6,$04
  DEFB $F5,$E5,$58,$DB,$86,$65,$B8,$0B
  DEFB $D9,$C5,$25,$6B,$55,$85,$75,$85
  DEFB $2A,$9A,$67,$89,$56,$D9,$CB,$5D
  DEFB $96,$66,$B5,$BA,$67,$78,$80,$12
  DEFB $78,$D0,$F8,$15,$A8,$0A,$09,$10
  DEFB $1A,$11,$78,$00,$38,$01,$DB,$86
  DEFB $26,$48,$50,$5B,$52,$56,$8D,$99
  DEFB $8B,$4B,$04,$81,$38,$06,$D9,$58
  DEFB $10,$5B,$95,$6B,$DA,$FA,$80,$85
  DEFB $95,$B9,$5F,$52,$58,$5E,$A6,$48
  DEFB $56,$58,$5B,$98,$5E,$57,$DC,$A5
  DEFB $D5,$E5,$7B,$5D,$96,$48,$50,$5E
  DEFB $9A,$5D,$A7,$88,$10,$4C,$B5,$EA
  DEFB $98,$08,$10,$DB,$88,$06,$66,$5B
  DEFB $55,$5E,$5B,$54,$26,$86,$76,$66
  DEFB $B5,$B5,$56,$22,$68,$67,$57,$9B
  DEFB $5B,$80,$15,$BB,$50,$50,$2B,$3B
  DEFB $80,$51,$01,$A8,$21,$78,$00,$BA
  DEFB $83,$A8,$C5,$8D,$BE,$06,$17,$64
  DEFB $80,$15,$7B,$50,$50,$26,$85,$F5
  DEFB $85,$24,$C9,$83,$48,$4B,$98,$D7
  DEFB $B4,$D8,$5B,$95,$99,$B5,$D9,$4D
  DEFB $31,$AB,$62,$26,$65,$88,$86,$AE
  DEFB $37,$4F,$DA,$F2,$BD,$7F,$98,$DF
  DEFB $48,$DC,$A8,$5E,$A9,$80,$84,$BB
  DEFB $4D,$85,$5D,$9C,$50,$5E,$B5,$09
  DEFB $6A,$00,$37,$D6,$9D,$66,$08,$10
  DEFB $E1,$E8,$E3,$F7,$88,$16,$12,$83
  DEFB $A8,$D4,$B8,$01,$56,$B5,$B5,$F9
  DEFB $55,$55,$58,$5E,$A8,$5F,$52,$96
  DEFB $08,$08,$10,$D3,$DA,$5A,$5E,$98
  DEFB $A4,$CD,$FD,$95,$B6,$28,$BC,$48
  DEFB $10,$2C,$66,$EB,$78,$82,$90,$60
  DEFB $1D,$59,$83,$B8,$D0,$82,$68,$14
  DEFB $D6,$C8,$10,$3F,$67,$78,$00,$38
  DEFB $01,$DA,$EA,$51,$58,$59,$80,$51
  DEFB $0D,$9B,$80,$81,$38,$06,$01,$A5
  DEFB $6D,$DE,$95,$B2,$68,$DC,$A5,$09
  DEFB $66,$E4,$B8,$22,$01,$5B,$2B,$51
  DEFB $58,$5D,$84,$BB,$5B,$85,$56,$22
  DEFB $68,$BD,$5F,$85,$25,$D6,$77,$88
  DEFB $D9,$C8,$3B,$80,$91,$01,$E0,$E8
  DEFB $D0,$8A,$80,$91,$03,$D8,$0B,$D9
  DEFB $C5,$8D,$9D,$81,$5A,$81,$1C,$87
  DEFB $8F,$00,$3A,$70,$5B,$98,$01,$59
  DEFB $DA,$F5,$48,$A5,$55,$25,$66,$28
  DEFB $60,$58,$5B,$56,$86,$05,$B5,$25
  DEFB $05,$05,$52,$68,$BC,$48,$05,$10
  DEFB $4D,$52,$5B,$5D,$75,$00,$38,$01
  DEFB $D3,$72,$66,$65,$58,$A5,$E5,$BC
  DEFB $42,$B0,$3D,$80,$83,$56,$76,$66
  DEFB $B5,$56,$48,$29,$06,$01,$4F,$D0
  DEFB $99,$5B,$84,$B5,$85,$B4,$D9,$5B
  DEFB $2B,$D5,$C8,$D0,$82,$68,$1A,$C8
  DEFB $67,$78,$00,$3A,$70,$5B,$98,$05
  DEFB $01,$59,$5B,$95,$D5,$D6,$28,$D4
  DEFB $08,$A5,$E5,$BC,$42,$B0,$34,$FD
  DEFB $09,$95,$BA,$82,$20,$15,$79,$02
  DEFB $55,$B6,$05,$77,$88,$05,$10,$D4
  DEFB $08,$D6,$AA,$80,$1D,$EA,$85,$6B
  DEFB $4D,$98,$08,$D5,$36,$48,$13,$8C
  DEFB $18,$01,$C2,$98,$C3,$8D,$9C,$81
  DEFB $D8,$D1,$78,$CB,$78,$00,$38,$01
  DEFB $59,$55,$9B,$AD,$9C,$5D,$8D,$EA
  DEFB $84,$F5,$E5,$B5,$75,$2A,$51,$2B
  DEFB $CA,$04,$82,$25,$65,$E5,$55,$D5
  DEFB $24,$C5,$85,$55,$85,$E5,$B2,$BD
  DEFB $53,$78,$00,$37,$51,$D4,$12,$68
  DEFB $C3,$80,$14,$FB,$52,$5B,$62,$5D
  DEFB $B5,$59,$8D,$EA,$8A,$95,$D8,$05
  DEFB $01,$A9,$01,$08,$DB,$97,$8F,$00
  DEFB $37,$4F,$55,$62,$26,$8C,$38,$01
  DEFB $5F,$BA,$5D,$8D,$42,$64,$80,$91
  DEFB $01,$18,$01,$50,$5B,$96,$28,$5B
  DEFB $52,$4B,$4B,$D6,$90,$8D,$16,$85
  DEFB $D6,$05,$2A,$5D,$A8,$52,$5D,$A8
  DEFB $D0,$D8,$CA,$81,$0D,$B9,$78,$00
  DEFB $D6,$48,$3A,$64,$80,$15,$D6,$05
  DEFB $2A,$5D,$26,$8D,$16,$8D,$08,$A8
  DEFB $CA,$81,$0D,$42,$81,$1C,$88,$09
  DEFB $01,$2C,$78,$00,$10,$2C,$85,$55
  DEFB $85,$85,$6A,$8D,$64,$82,$25,$25
  DEFB $DA,$8D,$46,$D2,$98,$66,$E4,$DC
  DEFB $F4,$D6,$76,$66,$BE,$4D,$1D,$8C
  DEFB $71,$05,$65,$8B,$5D,$67,$78,$00
  DEFB $37,$4F,$55,$62,$26,$8C,$70,$15
  DEFB $FB,$A5,$D8,$D4,$28,$09,$10,$1A
  DEFB $80,$81,$02,$C7,$8F,$00,$37,$A5
  DEFB $DB,$DA,$DB,$5B,$62,$84,$B9,$D0
  DEFB $B8,$10,$D6,$60,$81,$0E,$1E,$8E
  DEFB $3F,$66,$54,$8D,$69,$13,$8D,$6A
  DEFB $A8,$01,$D8,$5D,$FD,$86,$0D,$BD
  DEFB $95,$B8,$5F,$D9,$C9,$67,$78,$00
  DEFB $10,$1F,$A8,$D4,$B8,$D4,$A8,$04
  DEFB $80,$50,$1D,$23,$8A,$54,$62,$64
  DEFB $81,$0E,$9B,$5B,$DB,$E8,$06,$DF
  DEFB $38,$01,$50,$5B,$9D,$FD,$80,$B4
  DEFB $B5,$55,$E9,$85,$6B,$AA,$84,$FB
  DEFB $5B,$8D,$64,$78,$66,$56,$82,$90
  DEFB $60,$1D,$0F,$80,$51,$0A,$54,$62
  DEFB $81,$28,$D0,$82,$68,$05,$09,$01
  DEFB $33,$78,$67,$00,$10,$D0,$7A,$80
  DEFB $81,$0E,$2C,$8E,$D2,$31,$F8,$DF
  DEFB $B8,$04,$8D,$64,$83,$A6,$48,$10
  DEFB $2C,$85,$25,$DA,$95,$54,$F8,$06
  DEFB $01,$4D,$58,$5D,$80,$51,$04,$D5
  DEFB $2A,$5D,$D9,$C4,$C9,$78,$00,$37
  DEFB $05,$01,$D9,$78,$A5,$E5,$B5,$B9
  DEFB $B5,$58,$33,$8D,$08,$26,$80,$50
  DEFB $90,$14,$B5,$BD,$0A,$31,$55,$52
  DEFB $5D,$64,$85,$75,$85,$2A,$62,$85
  DEFB $1D,$A6,$78,$00,$38,$DF,$58,$08
  DEFB $01,$D4,$D1,$78,$8D,$7A,$82,$2D
  DEFB $65,$26,$8D,$44,$A7,$8F,$00,$38
  DEFB $DF,$58,$08,$01,$D4,$D1,$76,$48
  DEFB $D7,$A8,$22,$D6,$52,$68,$D4,$4A
  DEFB $78,$00,$38,$DF,$58,$08,$01,$D4
  DEFB $D1,$78,$D7,$A8,$22,$D6,$52,$68
  DEFB $D4,$4A,$78,$00,$38,$DF,$58,$08
  DEFB $01,$D4,$D1,$78,$64,$8D,$7A,$82
  DEFB $2D,$65,$26,$8D,$44,$A7,$8F,$00
  DEFB $37,$05,$01,$17,$8D,$9E,$82,$1A
  DEFB $80,$CD,$68,$5B,$2B,$22,$4F,$55
  DEFB $BA,$51,$26,$85,$5D,$0A,$A7,$88
  DEFB $29,$06,$01,$D4,$C8,$05,$D7,$F9
  DEFB $82,$D6,$65,$78,$CF,$80,$9D,$56
  DEFB $01,$51,$5E,$56,$56,$26,$8D,$B4
  DEFB $80,$64,$C5,$85,$62,$68,$D8,$36
  DEFB $77,$8F,$00,$37,$05,$01,$5B,$94
  DEFB $C9,$AA,$80,$81,$0D,$44,$81,$76
  DEFB $48,$29,$06,$B6,$6D,$69,$1D,$67
  DEFB $66,$6B,$58,$8C,$F4,$D6,$78,$CB
  DEFB $81,$28,$56,$B4,$D9,$80,$85,$15
  DEFB $25,$05,$13,$15,$95,$85,$55,$2A
  DEFB $51,$2B,$56,$95,$DB,$55,$78,$00
  DEFB $38,$01,$66,$57,$4B,$5B,$D0,$A3
  DEFB $15,$55,$25,$D6,$76,$66,$B5,$7D
  DEFB $97,$67,$8D,$01,$4C,$5E,$4B,$52
  DEFB $4C,$55,$97,$88,$10,$D7,$F3,$11
  DEFB $58,$06,$10,$66,$6B,$58,$CF,$4D
  DEFB $86,$7C,$B8,$CA,$81,$38,$3A,$8C
  DEFB $59,$4D,$78,$00,$37,$05,$01,$4D
  DEFB $B6,$36,$35,$52,$68,$4C,$51,$B5
  DEFB $64,$B9,$5B,$64,$80,$51,$0D,$9B
  DEFB $80,$81,$38,$06,$01,$D3,$38,$5E
  DEFB $59,$D6,$90,$15,$99,$4D,$9A,$5D
  DEFB $B5,$57,$88,$10,$ED,$D2,$8E,$B5
  DEFB $B5,$D9,$56,$06,$06,$A9,$B5,$D2
  DEFB $B5,$E5,$9D,$69,$52,$5D,$75,$75
  DEFB $00,$37,$05,$01,$A5,$55,$85,$92
  DEFB $68,$33,$80,$A1,$38,$01,$4C,$5E
  DEFB $5D,$5D,$26,$8D,$74,$80,$64,$BD
  DEFB $09,$26,$78,$00,$38,$01,$D0,$5D
  DEFB $45,$81,$78,$55,$DA,$F2,$B2,$22
  DEFB $1A,$80,$85,$24,$C9,$78,$00,$00

UMESS_TAB:
  DEFB $00,$76,$50,$D0,$92,$68,$58,$52
  DEFB $55,$8D,$C1,$77,$00,$76,$DC,$16
  DEFB $6E,$5E,$64,$84,$C5,$E5,$B5,$BD
  DEFB $FD,$5D,$31,$DB,$F6,$77,$7F,$00
  DEFB $76,$4C,$D0,$C6,$65,$D8,$D8,$E2
  DEFB $68,$D6,$91,$02,$16,$77,$7F,$00
  DEFB $65,$65,$01,$5F,$58,$52,$4C,$98
  DEFB $16,$57,$58,$D5,$6D,$BE,$D4,$EA
  DEFB $78,$78,$78,$65,$88,$6A,$E6,$2E
  DEFB $58,$E5,$E8,$E5,$1E,$BE,$5F,$E9
  DEFB $8E,$AE,$58,$E5,$5E,$5F,$E9,$E4
  DEFB $D8,$E5,$DE,$51,$E9,$8E,$59,$E5
  DEFB $EE,$63,$E6,$3E,$55,$E9,$8E,$58
  DEFB $E4,$F8,$E5,$DE,$51,$E9,$8E,$AE
  DEFB $5D,$EB,$E5,$B6,$A6,$56,$57,$87
  DEFB $87,$8D,$BE,$DF,$D8,$DA,$68,$50
  DEFB $58,$9A,$85,$65,$85,$6D,$FD,$5D
  DEFB $B5,$B5,$23,$1D,$59,$78,$65,$00
  DEFB $74,$C2,$4D,$00,$10,$D5,$B8,$06
  DEFB $DF,$98,$A5,$55,$25,$95,$99,$5B
  DEFB $62,$8D,$CA,$83,$A8,$09,$DF,$07
  DEFB $8F,$00,$D9,$48,$01,$D8,$98,$94
  DEFB $FD,$CA,$5D,$64,$81,$0D,$5B,$8D
  DEFB $D4,$A8,$BD,$5F,$81,$02,$48,$5D
  DEFB $58,$C8,$81,$01,$57,$86,$5F,$00
  DEFB $10,$CB,$80,$6D,$F9,$82,$78,$DC
  DEFB $A8,$10,$D5,$B8,$09,$4F,$07,$CA
  DEFB $78,$00,$76,$25,$D5,$B7,$7F,$00
  DEFB $76,$A2,$65,$59,$81,$C7,$7F,$00
  DEFB $37,$C2,$8D,$13,$8D,$C8,$80,$95
  DEFB $BD,$9A,$81,$04,$D5,$2B,$56,$D7
  DEFB $F4,$D7,$8F,$00,$76,$25,$4D,$52
  DEFB $B5,$6D,$7F,$4D,$77,$00,$76,$4B
  DEFB $58,$60,$77,$00,$76,$4F,$5E,$55
  DEFB $55,$82,$78,$4B,$58,$5D,$5D,$55
  DEFB $97,$7F,$00,$01,$4F,$55,$BA,$51
  DEFB $80,$84,$B5,$55,$E9,$85,$5D,$0A
  DEFB $81,$61,$0A,$5D,$B4,$F4,$F8,$5D
  DEFB $95,$65,$95,$85,$BB,$5B,$52,$31
  DEFB $4B,$55,$DA,$F4,$DA,$83,$A8,$BA
  DEFB $80,$14,$C5,$B6,$28,$08,$51,$58
  DEFB $5B,$5B,$58,$5B,$89,$5B,$5E,$59
  DEFB $5D,$A8,$16,$10,$DB,$A7,$86,$5F
  DEFB $00,$10,$1C,$85,$9B,$AA,$9A,$8C
  DEFB $A8,$10,$DB,$08,$D8,$62,$68,$0A
  DEFB $10,$D4,$6D,$29,$80,$B2,$20,$1D
  DEFB $E5,$84,$C5,$BB,$A5,$18,$07,$4F
  DEFB $DA,$6A,$8B,$D5,$F8,$10,$56,$58
  DEFB $B5,$D7,$8F,$00,$76,$A9,$5D,$80
  DEFB $85,$49,$62,$A7,$7F,$00,$76,$D8
  DEFB $58,$50,$58,$4B,$55,$95,$D7,$7F
  DEFB $00,$76,$5B,$0C,$4C,$58,$DA,$F7
  DEFB $7F,$00,$76,$DB,$B8,$DD,$17,$7F
  DEFB $00,$29,$60,$BA,$80,$1D,$79,$8D
  DEFB $BB,$DF,$D2,$68,$01,$4D,$B5,$05
  DEFB $09,$5B,$86,$05,$1D,$FD,$83,$A8
  DEFB $C5,$94,$D7,$88,$BA,$85,$19,$8D
  DEFB $78,$A8,$3A,$64,$85,$19,$8D,$BE
  DEFB $5B,$58,$60,$A8,$07,$02,$3A,$78
  DEFB $78,$78,$07,$56,$52,$AA,$9A,$75
  DEFB $8E,$10,$D7,$98,$A5,$10,$4A,$86
  DEFB $AE,$57,$E5,$8E,$57,$E9,$8E,$58
  DEFB $E4,$F8,$E5,$EE,$A8,$EB,$E5,$BE
  DEFB $98,$E5,$FE,$9E,$5B,$E6,$28,$E5
  DEFB $0E,$58,$E5,$8E,$4D,$8E,$BE,$5D
  DEFB $8E,$5D,$E5,$1E,$52,$EA,$6A,$80
  DEFB $BD,$B5,$8B,$D0,$D7,$8F,$00,$3A
  DEFB $8A,$5D,$5B,$52,$54,$98,$10,$D2
  DEFB $46,$48,$D0,$60,$74,$D5,$89,$A8
  DEFB $C2,$84,$B5,$B9,$B5,$47,$58,$E0
  DEFB $70,$65,$84,$B5,$F5,$25,$85,$EA
  DEFB $31,$56,$B4,$D9,$80,$8D,$D8,$85
  DEFB $6B,$5D,$95,$B5,$2B,$55,$85,$8D
  DEFB $9D,$8D,$BE,$D9,$C8,$50,$55,$BA
  DEFB $A7,$8F,$00,$76,$D8,$58,$5B,$26
  DEFB $77,$00,$65,$10,$56,$58,$AB,$52
  DEFB $4C,$8A,$5D,$52,$5B,$A8,$0B,$10
  DEFB $17,$89,$4C,$51,$58,$9A,$80,$1D
  DEFB $BC,$26,$85,$F5,$85,$24,$C9,$8B
  DEFB $4D,$5F,$52,$A2,$68,$3A,$80,$9D
  DEFB $87,$81,$05,$B2,$67,$8F,$00,$65
  DEFB $DD,$D8,$60,$5B,$B5,$2D,$BE,$A8
  DEFB $D7,$28,$5E,$59,$D6,$93,$A7,$88
  DEFB $DB,$E9,$52,$5B,$8D,$08,$95,$B8
  DEFB $DB,$C9,$A7,$87,$87,$88,$6A,$3A
  DEFB $85,$25,$05,$75,$85,$B2,$B1,$06
  DEFB $0B,$5B,$57,$26,$64,$85,$75,$86
  DEFB $08,$3A,$85,$9B,$62,$8D,$CA,$80
  DEFB $72,$23,$A5,$B8,$55,$52,$4F,$97
  DEFB $58,$6A,$00,$65,$65,$58,$51,$84
  DEFB $D9,$B5,$B8,$75,$8E,$3A,$8D,$DA
  DEFB $8D,$78,$56,$80,$94,$B9,$84,$B5
  DEFB $BD,$BD,$26,$8D,$9C,$62,$85,$65
  DEFB $85,$B9,$64,$8D,$06,$55,$5E,$4C
  DEFB $54,$52,$31,$3A,$5B,$85,$95,$5D
  DEFB $0A,$8C,$18,$DA,$B8,$A5,$95,$85
  DEFB $D5,$D2,$B0,$31,$0E,$DD,$28,$60
  DEFB $51,$58,$80,$66,$0B,$5D,$4C,$51
  DEFB $26,$8C,$73,$A7,$88,$01,$5F,$58
  DEFB $52,$4C,$98,$DA,$FD,$0B,$83,$A5
  DEFB $B8,$DB,$68,$94,$C5,$15,$89,$A6
  DEFB $48,$6A,$ED,$BE,$06,$5A,$5E,$9A
  DEFB $5D,$80,$60,$8A,$5E,$4C,$51,$85
  DEFB $25,$65,$95,$85,$B5,$DD,$9C,$4C
  DEFB $98,$09,$56,$98,$20,$E5,$28,$60
  DEFB $D9,$28,$5B,$9D,$AF,$4C,$B5,$B5
  DEFB $7B,$5D,$98,$3A,$6A,$64,$80,$BD
  DEFB $BE,$DF,$D8,$3A,$8D,$D5,$83,$A5
  DEFB $BA,$95,$54,$F8,$DC,$08,$05,$4F
  DEFB $B5,$65,$25,$55,$2B,$5B,$8A,$5E
  DEFB $5B,$C4,$26,$A7,$87,$87,$86,$5F
  DEFB $00,$8F,$00,$BA,$81,$0D,$F8,$85
  DEFB $95,$85,$E5,$BA,$80,$46,$48,$10
  DEFB $4B,$58,$5D,$5D,$55,$98,$4D,$52
  DEFB $AC,$6A,$87,$5F,$00,$10,$D5,$58
  DEFB $D6,$F4,$D9,$A8,$AC,$D2,$68,$D2
  DEFB $88,$4F,$55,$62,$26,$89,$D6,$26
  DEFB $01,$27,$88,$BA,$81,$04,$D5,$EA
  DEFB $5D,$8D,$37,$A8,$3A,$8D,$78,$80
  DEFB $7C,$18,$51,$B4,$D8,$50,$58,$58
  DEFB $4D,$89,$4F,$4F,$94,$C5,$D7,$8F
  DEFB $00,$10,$D5,$58,$D6,$F4,$D9,$A8
  DEFB $51,$B5,$B5,$6D,$91,$55,$62,$64
  DEFB $84,$D5,$82,$68,$55,$52,$5D,$5D
  DEFB $55,$98,$4D,$B5,$6B,$50,$97,$8F
  DEFB $00,$57,$58,$85,$6B,$5D,$5D,$95
  DEFB $B8,$DF,$68,$51,$B5,$B4,$D8,$3A
  DEFB $85,$D5,$B6,$26,$48,$10,$28,$86
  DEFB $0D,$92,$8C,$28,$56,$58,$5F,$98
  DEFB $16,$10,$D0,$37,$8F,$00,$76,$28
  DEFB $8A,$5D,$52,$4C,$54,$26,$80,$48
  DEFB $08,$10,$2F,$08,$01,$D2,$67,$7F
  DEFB $00,$76,$28,$77,$00,$76,$A5,$D5
  DEFB $24,$C5,$48,$08,$D5,$57,$7F,$00
  DEFB $76,$27,$8D,$B3,$66,$E5,$48,$22
  DEFB $D0,$20,$55,$25,$D6,$77,$7F,$00
  DEFB $76,$D8,$5D,$FD,$84,$C5,$B5,$86
  DEFB $05,$77,$7F,$00,$65,$BA,$83,$A8
  DEFB $36,$64,$83,$A8,$C2,$52,$4C,$98
  DEFB $20,$10,$DB,$38,$06,$55,$95,$D5
  DEFB $D2,$68,$05,$D0,$20,$B5,$6B,$62
  DEFB $8A,$58,$D6,$9A,$DA,$F5,$47,$5F
  DEFB $00,$5E,$57,$DC,$A5,$D5,$E5,$7B
  DEFB $5D,$95,$56,$26,$48,$10,$DB,$38
  DEFB $34,$85,$75,$88,$D1,$29,$5B,$8A
  DEFB $5D,$B6,$28,$B4,$F5,$55,$8B,$5D
  DEFB $78,$80,$7A,$DA,$F5,$4A,$80,$B3
  DEFB $A8,$A5,$D5,$B5,$E5,$05,$05,$59
  DEFB $80,$55,$FB,$05,$09,$A5,$DB,$62
  DEFB $8B,$4F,$55,$58,$B5,$D7,$87,$87
  DEFB $88,$D0,$64,$FB,$52,$55,$80,$B4
  DEFB $D5,$B5,$86,$05,$78,$05,$10,$D0
  DEFB $20,$81,$0E,$4F,$55,$B5,$62,$68
  DEFB $EC,$E7,$8F,$00,$65,$65,$10,$D5
  DEFB $58,$37,$DC,$D2,$68,$34,$C2,$8D
  DEFB $6A,$81,$0D,$AF,$5D,$DF,$DA,$98
  DEFB $D3,$B8,$16,$10,$CE,$80,$B0,$50
  DEFB $14,$B5,$5D,$AF,$4D,$26,$84,$F5
  DEFB $5B,$A5,$16,$48,$07,$D6,$F4,$D9
  DEFB $A6,$48,$A4,$CB,$5D,$5D,$95,$B2
  DEFB $68,$3A,$8B,$D5,$F8,$10,$DE,$28
  DEFB $13,$84,$B9,$D4,$AA,$84,$CB,$55
  DEFB $56,$8B,$A8,$07,$4C,$55,$B5,$25
  DEFB $6A,$8D,$9C,$58,$D9,$D8,$B4,$D5
  DEFB $FD,$FD,$5D,$5E,$5B,$98,$5F,$52
  DEFB $4C,$5D,$52,$56,$87,$57,$5F,$00
  DEFB $37,$E5,$7E,$58,$E5,$D8,$01,$50
  DEFB $51,$58,$A5,$D8,$0B,$34,$C2,$86
  DEFB $0B,$55,$54,$8C,$A8,$D0,$C2,$BC
  DEFB $BA,$75,$00,$76,$59,$5E,$55,$AB
  DEFB $5D,$26,$85,$85,$B4,$B7,$7F,$00
  DEFB $76,$5F,$52,$B5,$57,$7F,$00,$76
  DEFB $DE,$58,$DC,$38,$4B,$5B,$DB,$D2
  DEFB $68,$2E,$66,$E5,$66,$48,$13,$8C
  DEFB $6A,$80,$94,$B9,$8B,$A5,$59,$95
  DEFB $96,$77,$7F,$00,$76,$D1,$18,$2E
  DEFB $77,$00,$65,$60,$51,$DF,$D8,$3A
  DEFB $85,$BD,$9A,$8D,$BE,$06,$CD,$64
  DEFB $80,$1A,$54,$95,$59,$5D,$D6,$95
  DEFB $B5,$24,$D2,$68,$05,$D2,$38,$B5
  DEFB $B5,$65,$85,$E5,$B8,$DC,$D2,$68
  DEFB $01,$DE,$58,$5D,$60,$58,$8D,$CC
  DEFB $2B,$28,$8D,$D6,$A7,$87,$87,$88
  DEFB $6A,$10,$ED,$9C,$50,$95,$58,$08
  DEFB $E4,$DD,$BD,$8C,$18,$D4,$A8,$09
  DEFB $4C,$55,$B5,$25,$68,$3A,$5B,$85
  DEFB $55,$24,$F9,$75,$6A,$00,$BA,$83
  DEFB $A8,$A5,$D9,$59,$8D,$AF,$64,$80
  DEFB $1A,$54,$95,$59,$5D,$D6,$95,$15
  DEFB $85,$BA,$95,$6D,$9C,$8C,$5A,$81
  DEFB $01,$A8,$CD,$80,$81,$0D,$32,$64
  DEFB $8D,$06,$06,$5E,$57,$D8,$28,$09
  DEFB $5B,$D9,$A8,$3A,$8D,$8A,$05,$10
  DEFB $D3,$17,$8F,$00,$22,$01,$59,$52
  DEFB $95,$B4,$C2,$68,$A5,$15,$B5,$29
  DEFB $54,$64,$81,$05,$15,$85,$BA,$95
  DEFB $6D,$9C,$84,$D5,$2A,$C6,$A7,$87
  DEFB $87,$88,$3A,$8D,$4B,$84,$BD,$9C
  DEFB $52,$A5,$12,$B1,$0E,$D9,$C5,$09
  DEFB $55,$80,$8E,$4D,$DB,$D8,$DC,$08
  DEFB $09,$E5,$19,$55,$55,$87,$5F,$00
  DEFB $76,$1F,$73,$D4,$74,$D8,$50,$95
  DEFB $67,$7F,$00,$76,$D1,$58,$A4,$C5
  DEFB $B5,$85,$55,$57,$7F,$00,$76,$53
  DEFB $9D,$19,$2B,$A4,$C9,$59,$5D,$5B
  DEFB $97,$7F,$00,$76,$50,$57,$B5,$B5
  DEFB $52,$BA,$5D,$B4,$F4,$F7,$7F,$00
  DEFB $76,$57,$9A,$5D,$80,$8D,$85,$DF
  DEFB $D8,$95,$05,$0A,$77,$00,$3A,$85
  DEFB $6D,$9C,$B5,$09,$80,$94,$C5,$52
  DEFB $68,$D6,$90,$91,$0F,$0E,$8D,$0B
  DEFB $64,$8D,$06,$4F,$99,$55,$8D,$D8
  DEFB $DB,$E2,$68,$4D,$5B,$58,$59,$81
  DEFB $63,$A5,$B8,$50,$5B,$BA,$59,$75
  DEFB $00,$10,$DB,$A8,$A4,$C5,$84,$F4
  DEFB $FA,$80,$2D,$BE,$52,$A6,$48,$4C
  DEFB $58,$56,$56,$DF,$D5,$DA,$85,$E5
  DEFB $9D,$69,$10,$55,$B4,$C5,$48,$08
  DEFB $50,$DF,$D9,$5B,$58,$A5,$25,$D6
  DEFB $28,$05,$B4,$D5,$FD,$FD,$5D,$5E
  DEFB $5B,$98,$59,$55,$B6,$29,$5B,$A8
  DEFB $0B,$5B,$94,$F5,$EA,$9A,$80,$9B
  DEFB $4C,$4C,$95,$95,$D8,$52,$5D,$78
  DEFB $00,$65,$01,$D4,$98,$CB,$81,$DA
  DEFB $84,$BD,$FD,$DB,$D8,$3A,$5B,$84
  DEFB $F9,$95,$D8,$0B,$3A,$85,$95,$55
  DEFB $E5,$65,$69,$5D,$8D,$AA,$C8,$78
  DEFB $78,$78,$65,$00,$76,$DB,$A8,$D2
  DEFB $E2,$68,$3A,$5B,$8D,$0D,$8B,$D5
  DEFB $F8,$10,$D2,$96,$66,$C6,$48,$60
  DEFB $51,$58,$85,$D9,$55,$55,$A8,$3A
  DEFB $82,$05,$19,$70,$55,$55,$84,$D5
  DEFB $2A,$C6,$85,$24,$F8,$3A,$85,$05
  DEFB $25,$F9,$85,$15,$25,$68,$01,$A5
  DEFB $E5,$25,$DD,$82,$84,$B5,$B5,$24
  DEFB $B9,$67,$77,$00,$76,$D0,$38,$D5
  DEFB $B8,$08,$01,$DB,$A8,$50,$5E,$B5
  DEFB $B4,$D7,$7F,$00,$10,$DB,$A8,$DF
  DEFB $38,$55,$B5,$E5,$05,$1A,$80,$23
  DEFB $A5,$B8,$59,$5E,$57,$62,$8D,$FC
  DEFB $80,$9D,$D6,$85,$15,$25,$68,$0B
  DEFB $A5,$15,$B5,$E5,$0A,$80,$7D,$88
  DEFB $22,$59,$5B,$B4,$C5,$D5,$2A,$2B
  DEFB $9B,$A9,$78,$00,$10,$DB,$A8,$D7
  DEFB $85,$6A,$80,$9D,$C2,$8D,$BE,$06
  DEFB $BA,$85,$19,$85,$05,$BB,$4B,$A8
  DEFB $07,$0B,$DB,$58,$58,$4F,$4F,$78
  DEFB $00,$10,$D7,$48,$12,$80,$6D,$F9
  DEFB $8D,$7E,$DC,$A8,$3A,$80,$95,$5D
  DEFB $0A,$81,$0D,$C1,$75,$00,$01,$4C
  DEFB $55,$58,$5E,$4D,$80,$8A,$56,$58
  DEFB $54,$98,$5B,$52,$A9,$A8,$16,$10
  DEFB $4B,$5B,$58,$54,$DF,$D8,$5F,$52
  DEFB $B5,$57,$8F,$00,$10,$94,$F4,$F9
  DEFB $4C,$5D,$80,$81,$05,$0B,$A8,$C1
  DEFB $85,$A5,$E5,$24,$C5,$43,$16,$05
  DEFB $85,$B5,$78,$D8,$80,$B1,$02,$E8
  DEFB $60,$1B,$A8,$5E,$59,$78,$00,$10
  DEFB $2E,$80,$6D,$05,$D9,$C5,$05,$B6
  DEFB $28,$02,$3A,$5B,$8D,$AF,$5D,$5B
  DEFB $5E,$A5,$2D,$69,$0B,$AD,$F6,$A8
  DEFB $07,$03,$4F,$5B,$62,$26,$83,$A8
  DEFB $22,$01,$4B,$5E,$5B,$A5,$D8,$08
  DEFB $DC,$38,$75,$65,$00,$D7,$F9,$80
  DEFB $81,$0D,$E7,$8D,$78,$A8,$3A,$80
  DEFB $BD,$94,$80,$14,$B5,$B5,$29,$4F
  DEFB $84,$CD,$7F,$5F,$95,$BA,$BD,$AD
  DEFB $64,$85,$19,$85,$95,$24,$C5,$4A
  DEFB $80,$AD,$D8,$DB,$E2,$68,$20,$D6
  DEFB $0A,$80,$BD,$B5,$80,$48,$08,$10
  DEFB $58,$D9,$D8,$3B,$78,$00,$76,$25
  DEFB $D8,$58,$57,$5E,$50,$50,$95,$D7
  DEFB $7F,$00,$10,$D3,$38,$56,$58,$5F
  DEFB $9A,$89,$BA,$52,$31,$09,$DE,$F8
  DEFB $01,$D0,$E3,$28,$D6,$48,$52,$5D
  DEFB $78,$00,$76,$A5,$25,$55,$F9,$5B
  DEFB $8D,$5F,$77,$00,$3A,$8D,$7B,$80
  DEFB $14,$C5,$1D,$AF,$54,$8B,$A8,$07
  DEFB $51,$52,$5D,$A8,$10,$D1,$98,$D1
  DEFB $A7,$8F,$00,$8F,$00,$10,$2E,$66
  DEFB $E5,$D7,$0A,$84,$B5,$84,$D6,$26
  DEFB $78,$06,$D2,$E2,$68,$20,$15,$78
  DEFB $00,$76,$4C,$58,$52,$55,$80,$89
  DEFB $55,$5F,$DF,$D8,$DB,$07,$7F,$00
  DEFB $76,$55,$DF,$D5,$0D,$BE,$80,$8D
  DEFB $B0,$84,$DD,$9C,$50,$55,$26,$81
  DEFB $4D,$09,$8D,$C8,$8D,$CA,$83,$A8
  DEFB $09,$DC,$98,$14,$D8,$37,$7F,$00
  DEFB $A5,$D5,$BB,$4D,$52,$5F,$B5,$B5
  DEFB $25,$EA,$85,$F5,$25,$85,$5D,$AF
  DEFB $77,$00,$D9,$C8,$B6,$04,$F5,$E5
  DEFB $58,$57,$58,$52,$A9,$8D,$FD,$A5
  DEFB $E9,$A8,$BA,$83,$A8,$59,$55,$B6
  DEFB $28,$DB,$E0,$64,$B9,$B5,$E5,$D5
  DEFB $24,$F5,$E5,$58,$DA,$FA,$5D,$5B
  DEFB $5E,$56,$DF,$D5,$D8,$22,$A5,$E4
  DEFB $C5,$18,$01,$4B,$58,$60,$75,$00
  DEFB $76,$57,$9A,$5D,$80,$8D,$85,$DF
  DEFB $D8,$95,$05,$0A,$8D,$A9,$2B,$03
  DEFB $DD,$D8,$4F,$52,$95,$B4,$C9,$8D
  DEFB $F7,$A7,$7F,$00,$07,$06,$A5,$88
  DEFB $4B,$B4,$D8,$20,$10,$DF,$7A,$84
  DEFB $F3,$15,$84,$F4,$F7,$8F,$00,$A6
  DEFB $05,$25,$65,$62,$68,$06,$C2,$80
  DEFB $15,$05,$85,$84,$D8,$52,$4D,$90
  DEFB $1A,$DA,$F4,$C9,$8D,$05,$57,$BA
  DEFB $5D,$62,$85,$6D,$7F,$A5,$D9,$5B
  DEFB $A8,$0C,$5B,$5E,$56,$58,$5E,$5B
  DEFB $2B,$09,$55,$5E,$5B,$54,$80,$51
  DEFB $0D,$76,$A8,$BC,$48,$12,$75,$00
  DEFB $10,$DB,$38,$06,$DF,$98,$D6,$E8
  DEFB $DC,$A8,$3A,$80,$95,$D1,$B8,$58
  DEFB $5B,$84,$D5,$BB,$50,$8B,$D0,$D7
  DEFB $5F,$00,$01,$56,$52,$A4,$C5,$15
  DEFB $29,$5F,$58,$5E,$A8,$D6,$32,$68
  DEFB $50,$57,$58,$56,$98,$06,$DE,$F2
  DEFB $B6,$05,$15,$86,$48,$5B,$9B,$55
  DEFB $52,$A2,$68,$20,$51,$98,$06,$57
  DEFB $58,$60,$8D,$E1,$64,$8D,$B5,$8D
  DEFB $88,$05,$D8,$98,$C1,$5D,$97,$8F
  DEFB $00,$68,$65,$D9,$C8,$DA,$FD,$E1
  DEFB $8D,$CC,$8A,$51,$58,$5F,$9A,$83
  DEFB $A8,$DC,$08,$10,$D0,$D8,$3A,$84
  DEFB $CB,$56,$98,$0B,$50,$52,$5F,$9A
  DEFB $80,$1D,$7B,$5D,$62,$85,$5B,$5E
  DEFB $50,$51,$75,$65,$00,$10,$21,$A8
  DEFB $D4,$A8,$5D,$58,$50,$9D,$9D,$82
  DEFB $20,$1A,$52,$4C,$54,$DF,$D2,$68
  DEFB $A5,$A5,$E9,$55,$4C,$51,$80,$B4
  DEFB $C5,$B5,$E5,$74,$C5,$18,$75,$00
  DEFB $10,$21,$A8,$02,$10,$1A,$8C,$D8
  DEFB $1F,$5D,$84,$C5,$55,$8A,$26,$8D
  DEFB $8F,$31,$BA,$83,$A8,$59,$52,$4C
  DEFB $54,$80,$A1,$05,$05,$84,$B5,$59
  DEFB $5D,$75,$00,$BA,$81,$02,$1A,$85
  DEFB $BD,$9A,$81,$04,$BB,$5B,$64,$80
  DEFB $74,$BC,$DA,$80,$15,$55,$25,$D5
  DEFB $D5,$59,$64,$8D,$06,$51,$B5,$55
  DEFB $DA,$8D,$BE,$95,$25,$B8,$59,$5B
  DEFB $58,$50,$5B,$9A,$A7,$8F,$00,$76
  DEFB $4B,$B5,$08,$08,$4F,$55,$58,$5E
  DEFB $5B,$77,$00,$76,$A5,$D9,$95,$58
  DEFB $4B,$B5,$B6,$6E,$5F,$64,$84,$BD
  DEFB $FD,$5D,$8A,$55,$D0,$A3,$1B,$A8
  DEFB $07,$D8,$6A,$8D,$C0,$81,$02,$1A
  DEFB $67,$77,$00,$07,$4F,$DA,$6A,$81
  DEFB $41,$0D,$3E,$80,$B3,$A8,$D7,$B8
  DEFB $07,$D0,$78,$D7,$58,$D6,$47,$5F
  DEFB $00,$DD,$8D,$BE,$26,$83,$7D,$CD
  DEFB $26,$86,$0D,$7F,$70,$5D,$84,$F0
  DEFB $7C,$A8,$10,$CB,$D0,$D7,$5F,$00
  DEFB $37,$05,$01,$D0,$11,$78,$59,$B5
  DEFB $F2,$B2,$24,$64,$48,$D0,$15,$D5
  DEFB $25,$59,$A8,$D6,$91,$02,$47,$8F
  DEFB $00,$76,$A9,$5D,$80,$85,$85,$B5
  DEFB $7B,$56,$DF,$D5,$DB,$55,$84,$C5
  DEFB $19,$AA,$85,$95,$29,$4C,$9A,$77
  DEFB $00,$3A,$8D,$78,$84,$B5,$5D,$AF
  DEFB $4D,$26,$85,$5D,$0A,$A8,$0B,$A6
  DEFB $05,$25,$B5,$52,$68,$1F,$A8,$BA
  DEFB $8D,$D8,$8D,$CA,$4C,$98,$59,$52
  DEFB $4C,$54,$A8,$3A,$85,$E5,$97,$56
  DEFB $5F,$00,$8F,$00,$76,$85,$05,$89
  DEFB $A8,$A5,$88,$4F,$B5,$B7,$8F,$00
  DEFB $76,$85,$05,$89,$A8,$09,$4F,$DA
  DEFB $F5,$2A,$51,$78,$00,$86,$A3,$A8
  DEFB $D4,$B8,$4D,$D7,$F9,$8D,$19,$64
  DEFB $85,$65,$85,$B5,$DB,$55,$64,$80
  DEFB $95,$B9,$5D,$5E,$5B,$57,$81,$05
  DEFB $95,$86,$09,$5B,$85,$85,$B4,$B8
  DEFB $09,$56,$96,$65,$98,$0B,$09,$4F
  DEFB $95,$D4,$C5,$18,$DA,$68,$10,$5D
  DEFB $5B,$9B,$A5,$E5,$B9,$A8,$DC,$A8
  DEFB $3A,$5B,$A9,$55,$4F,$67,$78,$6A
  DEFB $65,$65,$86,$A5,$28,$D4,$B8,$D9
  DEFB $C5,$8D,$9D,$85,$A5,$E9,$A5,$D8
  DEFB $5E,$59,$D6,$91,$38,$09,$AC,$D8
  DEFB $3A,$64,$85,$24,$F8,$3A,$86,$0D
  DEFB $92,$8B,$4C,$4C,$95,$95,$D8,$01
  DEFB $56,$58,$5B,$98,$4D,$D9,$C5,$09
  DEFB $5B,$58,$5E,$A8,$5D,$BA,$54,$78
  DEFB $78,$78,$6A,$65,$65,$00,$8F,$00
  DEFB $10,$1C,$83,$6A,$85,$1B,$5B,$56
  DEFB $D9,$13,$1D,$6C,$81,$04,$D5,$2A
  DEFB $5D,$D9,$C4,$C9,$78,$65,$3A,$8D
  DEFB $4B,$8D,$F3,$84,$BD,$09,$57,$83
  DEFB $A5,$B8,$4C,$51,$D9,$C4,$C9,$80
  DEFB $8C,$52,$68,$10,$2C,$87,$5F,$00
  DEFB $3A,$83,$4C,$28,$4B,$B5,$25,$58
  DEFB $D0,$24,$FB,$A5,$D8,$DC,$88,$09
  DEFB $D4,$B8,$D9,$C6,$28,$94,$F4,$F9
  DEFB $4C,$5D,$75,$00,$76,$4F,$B4,$D2
  DEFB $B5,$6B,$A5,$D9,$5B,$59,$52,$94
  DEFB $C9,$66,$5E,$8D,$8E,$26,$8D,$69
  DEFB $10,$21,$67,$77,$00,$07,$4D,$52
  DEFB $AC,$6A,$8D,$64,$81,$0D,$E2,$82
  DEFB $20,$15,$05,$E5,$B5,$05,$59,$75
  DEFB $00,$10,$2E,$80,$64,$B9,$4C,$58
  DEFB $56,$26,$8D,$AF,$4C,$5B,$9B,$A2
  DEFB $63,$1B,$50,$52,$5D,$B5,$D2,$B0
  DEFB $33,$A5,$B8,$D9,$F4,$C9,$81,$27
  DEFB $5F,$00,$68,$3A,$83,$48,$D7,$F3
  DEFB $1D,$78,$80,$15,$B9,$4F,$55,$94
  DEFB $CD,$AD,$80,$81,$01,$77,$8F,$00
  DEFB $74,$D1,$1F,$00,$AD,$AF,$4C,$98
  DEFB $37,$60,$9B,$5B,$26,$81,$05,$B2
  DEFB $66,$48,$3A,$85,$6D,$9C,$B5,$09
  DEFB $80,$9A,$57,$9B,$54,$80,$AC,$F8
  DEFB $DC,$88,$09,$50,$95,$D8,$01,$50
  DEFB $58,$58,$4D,$8A,$60,$26,$80,$21
  DEFB $02,$E8,$22,$3A,$5B,$82,$87,$57
  DEFB $5F,$00,$D9,$48,$DC,$92,$68,$0A
  DEFB $0B,$14,$DC,$A8,$DD,$88,$DC,$F6
  DEFB $48,$37,$DC,$A4,$C9,$4D,$64,$84
  DEFB $B5,$BD,$BD,$D9,$15,$56,$26,$48
  DEFB $09,$A5,$D5,$85,$97,$5F,$00,$DF
  DEFB $67,$18,$E1,$0D,$C1,$80,$6D,$BF
  DEFB $75,$75,$75,$00,$3A,$8D,$DA,$8D
  DEFB $78,$56,$80,$9D,$4B,$80,$15,$49
  DEFB $62,$80,$94,$F0,$71,$27,$8F,$00
  DEFB $65,$3A,$5B,$8D,$C1,$8D,$78,$56
  DEFB $A8,$09,$4B,$98,$50,$95,$D5,$D2
  DEFB $68,$4D,$52,$56,$64,$8E,$52,$8D
  DEFB $BE,$DA,$F5,$48,$3A,$8D,$FA,$80
  DEFB $94,$FD,$92,$80,$75,$E5,$97,$86
  DEFB $5F,$00,$3A,$8D,$4B,$64,$85,$BB
  DEFB $D9,$D8,$5E,$57,$A5,$95,$85,$B5
  DEFB $D2,$65,$56,$26,$48,$54,$D9,$22
  DEFB $B1,$02,$E8,$DC,$BA,$5D,$85,$19
  DEFB $86,$0B,$A8,$BA,$55,$99,$59,$78
  DEFB $00,$10,$5B,$5E,$57,$9A,$8A,$B6
  DEFB $28,$6A,$EA,$56,$B5,$E5,$07,$0A
  DEFB $84,$BD,$9C,$96,$A7,$8F,$00,$68
  DEFB $65,$1F,$5D,$85,$DB,$59,$98,$DB
  DEFB $ED,$FD,$8D,$DF,$86,$AE,$62,$6A
  DEFB $65,$00,$65,$65,$88,$88,$88,$78
  DEFB $78,$78,$78,$78,$8A,$E5,$9E,$55
  DEFB $EB,$E5,$D8,$78,$78,$78,$78,$78
  DEFB $75,$75,$75,$75,$75,$65,$00,$07
  DEFB $4F,$55,$52,$9A,$80,$48,$08,$10
  DEFB $D0,$D8,$08,$3A,$5B,$84,$BD,$09
  DEFB $82,$25,$05,$BB,$4C,$94,$F5,$E5
  DEFB $58,$9B,$A9,$78,$00,$76,$D0,$1D
  DEFB $03,$77,$00,$65,$10,$2E,$84,$C5
  DEFB $85,$55,$5B,$59,$A9,$A8,$22,$01
  DEFB $1F,$5D,$55,$2B,$5B,$58,$B5,$B8
  DEFB $09,$4D,$52,$98,$05,$01,$D3,$A8
  DEFB $08,$50,$5B,$9D,$FD,$84,$B5,$55
  DEFB $85,$84,$D7,$8F,$00,$65,$DD,$32
  DEFB $68,$16,$5D,$B5,$99,$78,$65,$00
  DEFB $10,$DB,$79,$81,$DA,$82,$20,$15
  DEFB $95,$B5,$85,$D9,$A5,$D2,$68,$DD
  DEFB $07,$8F,$00,$07,$C6,$A8,$09,$4B
  DEFB $98,$D0,$C9,$4D,$78,$00,$BA,$83
  DEFB $A8,$59,$52,$4C,$54,$80,$75,$E5
  DEFB $96,$48,$3A,$8D,$7B,$80,$14,$C5
  DEFB $BB,$A5,$12,$66,$48,$5B,$58,$B5
  DEFB $B2,$68,$DB,$48,$D7,$58,$4F,$B5
  DEFB $B8,$C3,$78,$00,$10,$DB,$2A,$84
  DEFB $B9,$D4,$A8,$52,$56,$59,$DF,$D9
  DEFB $5D,$5B,$D8,$28,$05,$20,$DA,$57
  DEFB $8F,$00,$52,$4F,$83,$A8,$54,$99
  DEFB $59,$86,$0D,$9C,$4D,$95,$B2,$68
  DEFB $BC,$48,$05,$10,$D5,$96,$48,$37
  DEFB $55,$52,$D8,$28,$09,$4B,$98,$DD
  DEFB $62,$B0,$30,$1E,$4D,$95,$84,$DD
  DEFB $9C,$78,$65,$00,$58,$51,$85,$75
  DEFB $88,$75,$83,$A8,$D4,$B8,$57,$58
  DEFB $85,$5D,$0A,$80,$94,$D9,$4F,$CD
  DEFB $83,$A5,$BA,$95,$54,$F8,$BA,$80
  DEFB $1E,$4D,$95,$84,$DD,$9C,$8A,$60
  DEFB $58,$58,$59,$A8,$14,$09,$4D,$94
  DEFB $CB,$D9,$9B,$5D,$98,$3A,$88,$78
  DEFB $78,$78,$00,$29,$06,$C2,$51,$26
  DEFB $80,$8D,$AF,$5D,$95,$B9,$A5,$D8
  DEFB $0A,$10,$DB,$98,$09,$60,$B5,$B5
  DEFB $BD,$9C,$5D,$8A,$5E,$4C,$51,$80
  DEFB $15,$B5,$2A,$54,$62,$8B,$4C,$5D
  DEFB $8B,$A8,$DF,$02,$68,$DB,$E9,$56
  DEFB $78,$00,$65,$65,$88,$86,$05,$19
  DEFB $99,$99,$98,$78,$78,$78,$78,$78
  DEFB $78,$78,$75,$75,$00,$CC,$D9,$C8
  DEFB $58,$5B,$57,$B5,$D9,$31,$4D,$94
  DEFB $C5,$85,$BB,$5D,$2B,$4C,$D0,$C6
  DEFB $48,$A5,$D5,$E4,$D4,$D2,$B2,$25
  DEFB $39,$60,$95,$5A,$78,$80,$70,$65
  DEFB $75,$E5,$64,$B9,$5B,$2B,$D9,$C5
  DEFB $D5,$24,$CD,$0C,$60,$52,$A9,$80
  DEFB $BA,$DF,$6A,$81,$0D,$CF,$8B,$A8
  DEFB $46,$78,$43,$40,$87,$88,$29,$06
  DEFB $D9,$C8,$6A,$E5,$76,$A8,$DF,$D5
  DEFB $05,$BB,$5F,$2B,$C3,$81,$04,$14
  DEFB $27,$8F,$00,$CC,$01,$D5,$B8,$08
  DEFB $01,$50,$58,$4D,$85,$6B,$4D,$98
  DEFB $08,$59,$58,$55,$52,$A5,$12,$B5
  DEFB $6B,$5B,$4B,$55,$97,$80,$5D,$7F
  DEFB $98,$DC,$C8,$51,$98,$06,$D8,$62
  DEFB $68,$51,$06,$60,$B5,$B8,$51,$B5
  DEFB $65,$69,$5B,$80,$B0,$51,$05,$8D
  DEFB $9D,$64,$80,$4D,$FB,$2B,$DC,$C6
  DEFB $48,$29,$5B,$9A,$5D,$A8,$01,$25
  DEFB $4D,$52,$B5,$6D,$7F,$4D,$78,$00
  DEFB $07,$C1,$80,$1D,$05,$DB,$B8,$DB
  DEFB $66,$48,$D9,$C8,$DA,$F4,$C5,$18
  DEFB $60,$52,$4D,$97,$8F,$00,$CC,$01
  DEFB $4F,$DA,$F9,$31,$4C,$5B,$B4,$F5
  DEFB $D2,$B5,$65,$2D,$BE,$5B,$52,$55
  DEFB $8D,$D1,$82,$25,$B5,$E5,$79,$A8
  DEFB $4C,$B5,$B5,$F2,$B5,$E5,$9D,$69
  DEFB $10,$DC,$C5,$59,$78,$00,$07,$C1
  DEFB $80,$14,$D5,$2B,$50,$5B,$B5,$68
  DEFB $08,$01,$6A,$E4,$D6,$A8,$DF,$D4
  DEFB $C5,$25,$B4,$C5,$52,$68,$01,$CF
  DEFB $4D,$89,$62,$98,$95,$D4,$C5,$12
  DEFB $B5,$E5,$9D,$69,$52,$5D,$78,$00
  DEFB $CC,$01,$4B,$D1,$62,$88,$22,$10
  DEFB $57,$B5,$69,$86,$AE,$96,$14,$CB
  DEFB $55,$52,$4B,$5E,$5B,$6A,$8D,$E3
  DEFB $D6,$91,$0D,$03,$8D,$E6,$BD,$AF
  DEFB $26,$85,$25,$D7,$8F,$00,$8F,$00
  DEFB $07,$06,$01,$27,$8D,$B3,$64,$8D
  DEFB $05,$55,$D0,$A8,$09,$DC,$D7,$88
  DEFB $DC,$E8,$07,$C1,$80,$1D,$50,$8D
  DEFB $64,$85,$25,$DA,$8D,$76,$55,$DA
  DEFB $F9,$64,$80,$75,$6B,$62,$8D,$39
  DEFB $83,$67,$87,$87,$8D,$CA,$80,$1D
  DEFB $CB,$97,$5F,$00,$CC,$01,$4B,$58
  DEFB $5D,$5D,$55,$98,$D7,$A8,$22,$01
  DEFB $5F,$52,$A4,$C5,$85,$EA,$64,$8D
  DEFB $3B,$85,$B9,$A5,$2A,$5D,$D9,$C5
  DEFB $D8,$DF,$87,$8F,$00,$10,$A5,$D5
  DEFB $24,$C5,$4A,$80,$8D,$55,$80,$CD
  DEFB $68,$5B,$2B,$22,$01,$5F,$52,$A4
  DEFB $C5,$85,$EA,$8D,$F8,$78,$00,$CC
  DEFB $01,$DD,$86,$05,$10,$2A,$5E,$5B
  DEFB $5B,$9B,$55,$52,$A5,$D8,$D3,$D8
  DEFB $DE,$B4,$D8,$BC,$48,$5D,$60,$58
  DEFB $8D,$4F,$A8,$70,$56,$70,$8D,$69
  DEFB $01,$4F,$58,$5E,$5B,$8D,$01,$50
  DEFB $5B,$52,$4D,$82,$24,$C5,$19,$AA
  DEFB $85,$95,$29,$4C,$9A,$80,$51,$02
  DEFB $F0,$B0,$15,$42,$68,$D6,$95,$10
  DEFB $6D,$33,$8D,$86,$26,$8D,$9C,$85
  DEFB $85,$B4,$B7,$8F,$00,$10,$A5,$49
  DEFB $55,$95,$DD,$69,$06,$56,$D9,$CB
  DEFB $4C,$55,$2B,$09,$10,$D3,$38,$03
  DEFB $52,$5D,$A8,$DC,$CA,$80,$B4,$F9
  DEFB $95,$D6,$6E,$57,$64,$8D,$7F,$98
  DEFB $4F,$26,$95,$B8,$06,$59,$58,$DA
  DEFB $F5,$D2,$68,$DA,$AC,$86,$77,$8F
  DEFB $00,$07,$C1,$80,$1A,$55,$07,$05
  DEFB $10,$2F,$0B,$10,$57,$B5,$69,$86
  DEFB $AE,$96,$14,$CB,$55,$52,$4B,$5E
  DEFB $5B,$6A,$8D,$E3,$D6,$95,$25,$D7
  DEFB $8F,$00,$10,$D4,$62,$68,$06,$01
  DEFB $A5,$26,$18,$D0,$B4,$D8,$1F,$64
  DEFB $84,$CD,$7F,$A5,$D5,$B5,$E4,$C5
  DEFB $D2,$B1,$65,$D6,$05,$88,$5D,$5B
  DEFB $52,$D9,$C5,$05,$59,$A6,$48,$10
  DEFB $DA,$AC,$88,$59,$58,$DA,$F5,$D2
  DEFB $68,$D7,$F9,$82,$2D,$5D,$95,$B8
  DEFB $55,$DA,$F9,$A7,$8F,$00,$6A,$57
  DEFB $58,$85,$B9,$A5,$9D,$7F,$A5,$24
  DEFB $B5,$25,$55,$25,$D6,$28,$06,$B4
  DEFB $C4,$C9,$59,$5D,$2B,$DC,$A8,$4D
  DEFB $B5,$6B,$50,$9A,$84,$CB,$5E,$A2
  DEFB $B0,$9D,$9C,$62,$85,$99,$5B,$AD
  DEFB $69,$DD,$F2,$68,$DB,$E0,$6D,$4C
  DEFB $78,$6A,$00,$10,$A4,$C5,$B5,$25
  DEFB $95,$D8,$06,$56,$9D,$9C,$26,$D9
  DEFB $18,$09,$3A,$8B,$A8,$07,$06,$05
  DEFB $D9,$C8,$5E,$57,$4F,$B5,$65,$25
  DEFB $55,$2B,$5B,$85,$5D,$9C,$50,$5E
  DEFB $B5,$09,$78,$00,$65,$88,$88,$6A
  DEFB $88,$60,$98,$60,$95,$5D,$4A,$83
  DEFB $A8,$09,$E2,$C8,$ED,$23,$1F,$80
  DEFB $B5,$15,$85,$99,$83,$A5,$B8,$5F
  DEFB $52,$A0,$70,$60,$1A,$51,$58,$5B
  DEFB $5D,$80,$B5,$9B,$DA,$F4,$F5,$E5
  DEFB $58,$D7,$F9,$75,$88,$6A,$00,$D9
  DEFB $48,$DA,$42,$68,$BC,$48,$DC,$A8
  DEFB $DD,$88,$DC,$F6,$48,$3A,$85,$B9
  DEFB $95,$69,$5B,$50,$97,$87,$87,$86
  DEFB $5F,$00,$01,$DD,$02,$68,$DB,$48
  DEFB $D4,$AA,$81,$61,$01,$78,$D1,$88
  DEFB $3A,$8D,$96,$2B,$03,$01,$4C,$5B
  DEFB $BA,$51,$81,$6D,$75,$8D,$64,$78
  DEFB $00,$BA,$83,$A8,$C5,$94,$D6,$48
  DEFB $01,$D7,$98,$4D,$52,$AC,$62,$BC
  DEFB $A8,$D7,$F9,$80,$81,$05,$6D,$9C
  DEFB $62,$81,$5A,$78,$80,$55,$10,$6D
  DEFB $CC,$85,$19,$84,$CB,$5B,$5B,$52
  DEFB $2B,$DD,$8D,$BE,$26,$82,$0D,$60
  DEFB $94,$D7,$8F,$00,$07,$4D,$52,$AC
  DEFB $6A,$8B,$A8,$07,$51,$52,$5D,$A8
  DEFB $10,$24,$75,$00,$10,$DC,$18,$60
  DEFB $D9,$28,$D7,$F3,$15,$5D,$0A,$82
  DEFB $25,$85,$25,$58,$05,$52,$5D,$78
  DEFB $00,$10,$DC,$18,$52,$AA,$5E,$9A
  DEFB $80,$16,$65,$F4,$FD,$AF,$B5,$58
  DEFB $67,$A5,$95,$55,$E5,$D5,$D9,$5B
  DEFB $86,$65,$F4,$B9,$DC,$A9,$85,$05
  DEFB $82,$66,$76,$66,$B5,$FB,$A8,$10
  DEFB $D7,$48,$4B,$D0,$9A,$85,$25,$D6
  DEFB $78,$04,$75,$00,$07,$AB,$62,$A8
  DEFB $6D,$65,$88,$86,$AE,$60,$51,$DF
  DEFB $D8,$3A,$8D,$78,$83,$A5,$BA,$95
  DEFB $54,$F8,$BA,$80,$14,$F5,$B5,$2C
  DEFB $D8,$DB,$ED,$FD,$8A,$59,$9B,$54
  DEFB $64,$84,$F5,$B5,$2C,$D6,$48,$0B
  DEFB $C5,$80,$9D,$D5,$81,$0D,$A1,$80
  DEFB $81,$0E,$4F,$55,$B5,$62,$68,$EC
  DEFB $E6,$A7,$86,$5F,$00,$DD,$A8,$60
  DEFB $58,$5B,$5B,$62,$64,$86,$09,$70
  DEFB $55,$55,$84,$D5,$25,$08,$3A,$5B
  DEFB $85,$05,$BB,$5F,$98,$60,$51,$DF
  DEFB $D8,$3A,$85,$79,$2B,$09,$4B,$98
  DEFB $4B,$5E,$5B,$52,$94,$D7,$8F,$00
  DEFB $8F,$00,$6A,$4B,$96,$0B,$5B,$96
  DEFB $48,$4D,$9A,$5D,$5B,$58,$62,$26
  DEFB $85,$05,$84,$DA,$80,$64,$CD,$7F
  DEFB $D0,$B5,$B2,$B0,$1D,$05,$A9,$5B
  DEFB $52,$58,$5E,$A8,$58,$4F,$4F,$DF
  DEFB $D4,$C9,$6A,$00,$CC,$DE,$30,$5E
  DEFB $95,$55,$F5,$2A,$51,$8A,$4C,$5B
  DEFB $52,$59,$5D,$85,$E5,$7D,$CA,$5D
  DEFB $5E,$57,$B5,$D9,$55,$62,$78,$00
  DEFB $8F,$00,$8F,$00,$76,$56,$58,$5B
  DEFB $A9,$55,$80,$8D,$53,$77,$00,$01
  DEFB $4F,$5B,$52,$CD,$31,$4F,$B4,$C9
  DEFB $81,$F9,$A8,$02,$3A,$78,$00,$76
  DEFB $D8,$5D,$FD,$86,$0D,$BD,$95,$B8
  DEFB $5F,$D9,$C9,$77,$00,$76,$59,$B5
  DEFB $25,$B8,$08,$50,$55,$58,$5F,$9A
  DEFB $77,$00,$76,$5B,$2B,$51,$58,$5D
  DEFB $84,$BB,$5B,$77,$00,$10,$A5,$15
  DEFB $84,$C5,$48,$08,$D8,$62,$68,$10
  DEFB $50,$D0,$92,$68,$4B,$B5,$B8,$06
  DEFB $DF,$98,$56,$5E,$4C,$51,$8D,$CA
  DEFB $83,$A5,$B8,$D7,$B5,$D8,$BA,$83
  DEFB $A8,$54,$99,$55,$8C,$74,$C5,$55
  DEFB $E5,$D4,$C5,$12,$68,$3A,$5B,$84
  DEFB $C5,$19,$A5,$D7,$5F,$00,$10,$4B
  DEFB $B5,$B8,$4C,$58,$58,$55,$A8,$D8
  DEFB $F3,$10,$50,$14,$C5,$55,$85,$E4
  DEFB $D8,$08,$A5,$D9,$B5,$67,$8F,$00
  DEFB $59,$55,$9B,$A9,$86,$66,$CD,$87
  DEFB $67,$66,$71,$DD,$A8,$D4,$36,$78
  DEFB $10,$96,$15,$15,$24,$B5,$25,$DA
  DEFB $66,$6C,$8B,$55,$D7,$F9,$67,$78
  DEFB $00,$01,$D7,$96,$48,$D7,$B2,$68
  DEFB $3A,$8C,$56,$48,$DB,$58,$D8,$80
  DEFB $50,$1A,$4C,$B5,$B9,$64,$84,$D5
  DEFB $B5,$85,$95,$92,$68,$10,$DD,$18
  DEFB $20,$51,$98,$60,$BA,$8D,$BB,$DF
  DEFB $D2,$67,$8F,$00,$3A,$70,$5B,$98
  DEFB $55,$5E,$4C,$54,$62,$8C,$28,$09
  DEFB $4D,$52,$98,$4D,$5B,$DA,$F5,$42
  DEFB $68,$DB,$EB,$5D,$75,$8E,$BA,$80
  DEFB $75,$2A,$64,$83,$A8,$A5,$E4,$F4
  DEFB $F9,$5B,$84,$C5,$15,$BD,$7F,$52
  DEFB $4C,$8D,$AF,$4D,$52,$50,$9A,$DA
  DEFB $D7,$8F,$00,$29,$0C,$DF,$98,$56
  DEFB $D9,$C6,$28,$59,$52,$94,$C9,$A8
  DEFB $09,$59,$52,$4C,$54,$85,$E5,$96
  DEFB $66,$C8,$ED,$52,$67,$78,$00,$65
  DEFB $65,$3A,$8D,$4B,$84,$CB,$5B,$9D
  DEFB $91,$31,$60,$D9,$C4,$D9,$5B,$2B
  DEFB $DC,$08,$05,$12,$64,$85,$25,$05
  DEFB $75,$85,$B2,$68,$10,$60,$B5,$B5
  DEFB $72,$68,$0B,$59,$B6,$28,$10,$59
  DEFB $5B,$52,$4C,$98,$BA,$83,$A8,$5D
  DEFB $5E,$56,$4B,$55,$98,$CA,$81,$0D
  DEFB $49,$8C,$B8,$0B,$59,$55,$5E,$56
  DEFB $56,$95,$D8,$D8,$F3,$11,$41,$61
  DEFB $0D,$51,$26,$80,$80,$1D,$13,$81
  DEFB $77,$8F,$00,$56,$56,$56,$78,$78
  DEFB $78,$87,$62,$06,$0B,$A8,$57,$52
  DEFB $4C,$97,$5F,$00,$56,$56,$56,$78
  DEFB $78,$78,$87,$6D,$BE,$D9,$C5,$4A
  DEFB $75,$8E,$57,$58,$60,$8D,$F6,$8B
  DEFB $4B,$04,$85,$66,$28,$5D,$58,$55
  DEFB $55,$84,$F9,$97,$8F,$00,$76,$4B
  DEFB $17,$A5,$D5,$24,$C5,$47,$7F,$00
  DEFB $CC,$56,$B4,$D9,$80,$84,$B5,$25
  DEFB $B4,$C5,$18,$DB,$28,$0B,$C1,$80
  DEFB $15,$55,$25,$D5,$D5,$59,$85,$95
  DEFB $5B,$5A,$5E,$98,$D6,$91,$0D,$0B
  DEFB $78,$00,$10,$59,$55,$B5,$A5,$E9
  DEFB $8C,$18,$DE,$3D,$69,$07,$6D,$65
  DEFB $88,$86,$A8,$E6,$05,$BB,$52,$DB
  DEFB $E8,$E5,$0E,$61,$E5,$58,$42,$40
  DEFB $40,$40,$84,$B0,$25,$95,$86,$09
  DEFB $5B,$78,$8B,$5E,$5D,$58,$56,$B5
  DEFB $D5,$24,$C8,$5B,$95,$05,$E5,$5B
  DEFB $5D,$26,$84,$B1,$77,$88,$DF,$C8
  DEFB $4D,$95,$F5,$24,$C9,$8B,$4C,$5D
  DEFB $52,$5F,$BD,$AD,$84,$C5,$84,$D9
  DEFB $80,$B5,$B9,$5F,$95,$BA,$98,$DC
  DEFB $08,$B5,$0B,$DA,$F7,$88,$50,$DF
  DEFB $D9,$5B,$B5,$58,$E5,$6B,$50,$52
  DEFB $4C,$8E,$DA,$F4,$C7,$88,$6A,$00
  DEFB $66,$6C,$DD,$96,$48,$67,$60,$58
  DEFB $5B,$56,$A8,$34,$84,$D5,$88,$55
  DEFB $52,$5D,$5D,$55,$98,$58,$D9,$D8
  DEFB $DB,$ED,$9C,$86,$05,$B5,$25,$05
  DEFB $05,$59,$8B,$4B,$04,$66,$71,$8E
  DEFB $D5,$26,$77,$86,$5F,$00,$68,$65
  DEFB $3A,$8D,$63,$8B,$C4,$85,$05,$E5
  DEFB $25,$55,$D5,$23,$10,$9D,$78,$8D
  DEFB $9C,$85,$85,$54,$D8,$60,$58,$56
  DEFB $D9,$C8,$22,$01,$60,$B5,$55,$42
  DEFB $68,$A5,$D5,$24,$C5,$47,$88,$A5
  DEFB $19,$85,$65,$E5,$D5,$D9,$5B,$A6
  DEFB $48,$6A,$ED,$9C,$58,$D9,$D8,$5D
  DEFB $52,$5B,$9D,$D8,$8B,$4D,$5F,$DF
  DEFB $D5,$D5,$E5,$B9,$5B,$6A,$64,$8D
  DEFB $BE,$DF,$D8,$56,$58,$5B,$98,$05
  DEFB $A5,$85,$B5,$B5,$86,$08,$DB,$ED
  DEFB $9C,$8D,$9C,$50,$95,$B6,$48,$6A
  DEFB $E3,$A8,$DA,$FA,$52,$50,$57,$52
  DEFB $4F,$52,$34,$5D,$85,$55,$25,$D5
  DEFB $D5,$59,$86,$05,$85,$B5,$66,$A6
  DEFB $48,$0B,$D0,$5A,$58,$D6,$9D,$BE
  DEFB $B5,$D7,$0A,$89,$61,$B4,$C5,$D3
  DEFB $16,$05,$10,$23,$A8,$B5,$B9,$75
  DEFB $65,$00,$07,$4D,$52,$AC,$6A,$80
  DEFB $48,$08,$AD,$0A,$85,$D5,$8C,$8A
  DEFB $81,$05,$0C,$47,$8F,$00,$8F,$00
  DEFB $BA,$83,$A8,$55,$58,$A9,$85,$19
  DEFB $D0,$A6,$48,$57,$58,$8A,$B4,$F9
  DEFB $8D,$07,$26,$8B,$5B,$90,$1C,$6A
  DEFB $80,$B3,$A8,$4C,$5B,$BA,$51,$8D
  DEFB $6C,$81,$0D,$B9,$75,$00,$10,$56
  DEFB $B5,$05,$24,$C8,$A5,$EA,$5D,$BD
  DEFB $AF,$26,$83,$A5,$B8,$4F,$55,$D0
  DEFB $A8,$06,$77,$00,$76,$57,$9B,$5B
  DEFB $31,$96,$15,$1B,$5E,$A5,$D9,$4D
  DEFB $78,$00,$76,$96,$15,$1B,$5E,$A5
  DEFB $D2,$B0,$B5,$05,$BB,$5F,$52,$5D
  DEFB $62,$85,$D1,$BA,$8D,$41,$78,$78
  DEFB $78,$00,$76,$D0,$38,$B5,$55,$DB
  DEFB $5B,$77,$00,$07,$C1,$80,$14,$CB
  DEFB $5B,$5F,$26,$80,$80,$1D,$D2,$85
  DEFB $E5,$9D,$69,$07,$0B,$06,$60,$58
  DEFB $5B,$57,$80,$35,$65,$E4,$C5,$18
  DEFB $5E,$A9,$78,$00,$3A,$8D,$78,$80
  DEFB $15,$F5,$2A,$52,$D6,$90,$81,$0E
  DEFB $DD,$28,$66,$6B,$E5,$7D,$63,$26
  DEFB $81,$4B,$5D,$67,$66,$E5,$74,$B9
  DEFB $4C,$54,$D7,$F2,$68,$0A,$5D,$58
  DEFB $67,$83,$A8,$16,$10,$66,$6B,$E5
  DEFB $7A,$54,$52,$9A,$67,$66,$E5,$71
  DEFB $FA,$67,$78,$00,$3A,$8D,$FB,$80
  DEFB $48,$3A,$5B,$8D,$CC,$85,$D5,$8C
  DEFB $8A,$81,$05,$05,$59,$B5,$62,$68
  DEFB $59,$58,$DA,$F5,$DA,$81,$38,$D7
  DEFB $85,$68,$09,$5B,$94,$C9,$4D,$98
  DEFB $16,$3A,$5B,$85,$05,$BB,$A5,$97
  DEFB $8F,$00,$09,$3A,$5B,$85,$E5,$D5
  DEFB $D9,$5B,$8B,$56,$B6,$39,$56,$DF
  DEFB $D5,$D6,$48,$3A,$8A,$5E,$4C,$4C
  DEFB $99,$4D,$78,$82,$90,$60,$15,$D9
  DEFB $B5,$B2,$68,$DB,$48,$BA,$81,$0A
  DEFB $54,$62,$8D,$F5,$A8,$09,$DE,$F8
  DEFB $01,$D5,$98,$32,$80,$5D,$17,$80
  DEFB $83,$A7,$5F,$00,$01,$4B,$52,$5B
  DEFB $4D,$8A,$60,$58,$58,$59,$A8,$14
  DEFB $16,$10,$DB,$98,$BA,$80,$7D,$78
  DEFB $A8,$01,$5D,$BA,$5D,$62,$85,$69
  DEFB $B5,$57,$87,$87,$88,$3A,$75,$00
  DEFB $3A,$5B,$84,$B1,$7A,$5D,$52,$4C
  DEFB $54,$85,$5B,$4C,$54,$A8,$10,$59
  DEFB $58,$60,$95,$B8,$09,$5D,$1B,$83
  DEFB $A5,$B8,$DD,$38,$D9,$C6,$28,$51
  DEFB $52,$50,$51,$95,$B7,$8F,$00,$4F
  DEFB $55,$B5,$95,$92,$68,$3A,$5B,$8B
  DEFB $5B,$56,$A8,$DF,$38,$4C,$5B,$9B
  DEFB $5D,$9A,$80,$15,$65,$25,$54,$D8
  DEFB $4B,$5B,$99,$63,$97,$5F,$00,$10
  DEFB $CB,$8D,$D4,$A8,$66,$58,$1D,$67
  DEFB $66,$6B,$58,$A5,$15,$E5,$D6,$77
  DEFB $8F,$00,$BA,$83,$A8,$C5,$64,$81
  DEFB $0C,$B8,$DD,$4A,$8A,$51,$5E,$5D
  DEFB $80,$B0,$15,$35,$85,$55,$D8,$50
  DEFB $95,$DA,$83,$A8,$56,$58,$5F,$26
  DEFB $85,$E5,$9C,$87,$87,$87,$8F,$00
  DEFB $78,$78,$78,$87,$60,$B0,$15,$35
  DEFB $E4,$D4,$D9,$5B,$85,$1B,$55,$5D
  DEFB $A8,$3A,$5B,$85,$95,$B5,$85,$05
  DEFB $B9,$AA,$78,$65,$00,$65,$6A,$3A
  DEFB $8D,$4B,$84,$FB,$52,$55,$2B,$09
  DEFB $5B,$95,$D5,$E5,$B5,$78,$22,$10
  DEFB $58,$5B,$4B,$75,$8E,$52,$84,$BD
  DEFB $9C,$52,$A5,$18,$3A,$8D,$CA,$95
  DEFB $F9,$5B,$8D,$C0,$80,$91,$0D,$07
  DEFB $86,$05,$1D,$FD,$4C,$98,$3A,$8D
  DEFB $4B,$8D,$F3,$8D,$4A,$78,$78,$78
  DEFB $00,$86,$A8,$4C,$5E,$56,$56,$DA
  DEFB $F7,$0A,$8E,$DE,$A8,$6A,$00,$10
  DEFB $A5,$99,$55,$55,$86,$09,$B5,$BA
  DEFB $8D,$88,$0B,$3A,$8D,$D5,$83,$A5
  DEFB $BA,$95,$54,$F8,$DC,$08,$09,$57
  DEFB $58,$5B,$56,$B5,$57,$8F,$00,$76
  DEFB $D1,$18,$DD,$77,$7F,$00,$76,$66
  DEFB $6B,$5A,$56,$D9,$C6,$26,$76,$65
  DEFB $AA,$26,$55,$96,$78,$DB,$62,$BD
  DEFB $D7,$77,$00,$76,$57,$94,$C5,$45
  DEFB $5B,$4C,$97,$7F,$00,$CC,$56,$B4
  DEFB $D9,$80,$85,$9B,$55,$98,$4B,$55
  DEFB $5E,$98,$D0,$3A,$8D,$69,$01,$60
  DEFB $58,$5F,$DF,$D8,$A5,$25,$55,$F9
  DEFB $5B,$8D,$BE,$D4,$87,$8F,$00,$01
  DEFB $55,$D0,$AD,$FD,$26,$8D,$D6,$86
  DEFB $65,$AA,$5D,$5B,$52,$54,$9A,$81
  DEFB $05,$B9,$56,$BD,$AF,$4D,$26,$8D
  DEFB $B6,$80,$BD,$87,$A8,$10,$DD,$78
  DEFB $D1,$17,$86,$76,$66,$B5,$AD,$87
  DEFB $A8,$D7,$F9,$8D,$B6,$8D,$8E,$26
  DEFB $85,$55,$25,$65,$95,$56,$26,$48
  DEFB $D0,$63,$7C,$28,$5A,$5E,$52,$4C
  DEFB $54,$8D,$C8,$8D,$CA,$81,$05,$8D
  DEFB $9D,$A7,$87,$87,$86,$76,$5F,$00
  DEFB $3A,$8D,$7B,$8D,$9C,$8D,$9C,$50
  DEFB $5B,$62,$8D,$BC,$8B,$A8,$07,$5B
  DEFB $D9,$A9,$A8,$10,$D1,$A8,$08,$10
  DEFB $D9,$97,$8F,$00,$38,$D9,$62,$B0
  DEFB $31,$04,$B5,$B5,$29,$4F,$64,$8D
  DEFB $06,$4F,$9B,$5B,$DD,$86,$48,$57
  DEFB $58,$52,$A9,$80,$80,$14,$BB,$5D
  DEFB $5D,$55,$98,$C7,$10,$5D,$DA,$F6
  DEFB $28,$56,$58,$5B,$A9,$55,$78,$00
  DEFB $10,$66,$6B,$5A,$56,$5E,$55,$5D
  DEFB $52,$73,$DB,$69,$4D,$67,$66,$5A
  DEFB $D9,$C5,$05,$B6,$26,$78,$56,$D7
  DEFB $FA,$5D,$95,$B8,$5B,$52,$59,$A8
  DEFB $3A,$80,$95,$95,$29,$4C,$9A,$66
  DEFB $6B,$5A,$64,$85,$25,$DA,$8A,$95
  DEFB $9B,$5B,$B5,$D9,$8D,$B6,$A8,$5A
  DEFB $5E,$B5,$B5,$B9,$55,$55,$26,$8C
  DEFB $71,$04,$D5,$2A,$5D,$5B,$52,$4B
  DEFB $5E,$DA,$D8,$08,$3A,$5B,$85,$55
  DEFB $25,$64,$BA,$80,$B3,$A5,$B8,$55
  DEFB $B4,$C5,$48,$08,$A6,$09,$95,$D5
  DEFB $79,$AA,$67,$78,$00,$10,$DD,$78
  DEFB $DB,$C9,$A8,$56,$DF,$DB,$4C,$26
  DEFB $31,$BA,$86,$6A,$3A,$85,$65,$85
  DEFB $F9,$82,$0D,$0D,$67,$66,$6B,$A0
  DEFB $7C,$25,$24,$C9,$A8,$3A,$80,$55
  DEFB $25,$DA,$85,$5B,$52,$5B,$67,$78
  DEFB $00,$DB,$E0,$6D,$03,$80,$64,$D9
  DEFB $4D,$52,$4C,$B5,$D2,$B0,$9D,$BE
  DEFB $58,$A9,$86,$05,$15,$88,$D4,$B8
  DEFB $4F,$DF,$A8,$0B,$4D,$52,$2B,$56
  DEFB $D9,$C6,$28,$DC,$FA,$80,$51,$05
  DEFB $6B,$54,$26,$80,$8D,$BE,$06,$B4
  DEFB $D5,$FD,$FD,$5D,$5E,$5B,$98,$6D
  DEFB $65,$EB,$5E,$DB,$E5,$85,$B8,$73
  DEFB $8E,$56,$B5,$B5,$48,$EA,$51,$95
  DEFB $95,$9B,$5B,$4D,$65,$E4,$C5,$87
  DEFB $3B,$5E,$DB,$E5,$85,$BA,$87,$38
  DEFB $ED,$9C,$4D,$5B,$96,$08,$E4,$C5
  DEFB $E5,$65,$6D,$AF,$A6,$48,$E5,$09
  DEFB $D8,$8E,$5B,$52,$4C,$51,$B5,$B4
  DEFB $DA,$D7,$F6,$48,$E5,$65,$25,$49
  DEFB $8E,$5B,$94,$D5,$6D,$FD,$65,$ED
  DEFB $EB,$4D,$8D,$69,$D9,$C8,$58,$5B
  DEFB $52,$50,$DA,$FB,$55,$85,$24,$D9
  DEFB $01,$03,$E5,$99,$5D,$95,$B8,$EA
  DEFB $4C,$B5,$B5,$0D,$92,$78,$00,$86
  DEFB $AD,$BE,$06,$CB,$85,$65,$EA,$5D
  DEFB $85,$B9,$56,$B0,$51,$D6,$AF,$00
  DEFB $8F,$00,$76,$56,$26,$85,$FB,$A9
  DEFB $77,$00,$65,$10,$4C,$5E,$5B,$5B
  DEFB $DF,$D5,$D8,$59,$5B,$95,$FD,$FD
  DEFB $5D,$A8,$3A,$78,$00,$00

_MSG_TAB:
  DEFB $00,$68,$52,$66,$71,$70,$56,$8D
  DEFB $D9,$64,$8E,$52,$67,$8D,$DA,$8D
  DEFB $4E,$D6,$A8,$DB,$EB,$5D,$66,$6C
  DEFB $64,$8E,$D5,$26,$77,$8F,$00,$37
  DEFB $DB,$F8,$DC,$C9,$4D,$78,$00,$88
  DEFB $80,$16,$97,$8F,$00,$85,$25,$D6
  DEFB $66,$C7,$0A,$67,$66,$71,$85,$2A
  DEFB $67,$8D,$F3,$8D,$9C,$85,$85,$B4
  DEFB $DD,$AF,$B5,$B6,$28,$69,$78,$00
  DEFB $76,$80,$B6,$09,$B5,$B2,$68,$6D
  DEFB $65,$88,$8E,$01,$69,$78,$00,$52
  DEFB $8D,$DA,$8D,$BE,$DA,$F5,$48,$3A
  DEFB $85,$85,$B8,$10,$69,$86,$0D,$DE
  DEFB $8D,$C2,$8D,$BE,$B5,$D7,$8F,$00
  DEFB $66,$6C,$A5,$E4,$C5,$18,$4C,$51
  DEFB $52,$55,$4D,$52,$A5,$18,$DF,$CA
  DEFB $80,$25,$6B,$50,$52,$4C,$8D,$DA
  DEFB $8D,$AE,$80,$51,$26,$76,$67,$12
  DEFB $20,$14,$D9,$B4,$FD,$FD,$26,$8A
  DEFB $52,$55,$DF,$D4,$C9,$64,$8B,$4B
  DEFB $A5,$85,$55,$E5,$D9,$31,$C2,$51
  DEFB $26,$8D,$AC,$A6,$77,$5F,$00,$8F
  DEFB $00,$DB,$EB,$5D,$70,$A8,$C2,$80
  DEFB $16,$05,$2A,$98,$52,$4D,$9B,$78
  DEFB $00,$62,$5E,$54,$75,$00,$3A,$8B
  DEFB $5B,$DF,$D7,$05,$D8,$DC,$D2,$68
  DEFB $10,$69,$78,$00,$8F,$00,$8F,$00
  DEFB $8F,$00,$68,$66,$6C,$CC,$DF,$98
  DEFB $D5,$96,$76,$67,$11,$05,$5D,$0A
  DEFB $70,$A8,$C2,$85,$05,$85,$84,$D8
  DEFB $DC,$86,$78,$DC,$A8,$3A,$80,$9D
  DEFB $78,$8D,$9C,$62,$DB,$E2,$67,$8F
  DEFB $00,$37,$DC,$D2,$68,$6D,$65,$88
  DEFB $8E,$01,$69,$78,$00,$37,$60,$9B
  DEFB $5B,$26,$86,$D6,$58,$88,$E0,$16
  DEFB $97,$8F,$00,$66,$71,$29,$06,$01
  DEFB $69,$67,$66,$6C,$01,$69,$85,$2A
  DEFB $67,$81,$27,$8F,$00,$8F,$00,$68
  DEFB $52,$8D,$DA,$86,$66,$C5,$A5,$E5
  DEFB $25,$D9,$86,$7D,$96,$83,$A7,$88
  DEFB $DA,$28,$3A,$85,$B9,$73,$59,$51
  DEFB $5B,$BA,$98,$DB,$EB,$5D,$78,$00
  DEFB $68,$3A,$83,$47,$05,$D8,$50,$58
  DEFB $86,$67,$10,$52,$0D,$A5,$67,$66
  DEFB $6C,$20,$D0,$D6,$77,$8F,$00,$8F
  DEFB $00,$8F,$00,$66,$6C,$95,$15,$15
  DEFB $16,$76,$67,$16,$05,$1B,$5D,$67
  DEFB $78,$78,$78,$75,$75,$82,$04,$D5
  DEFB $89,$A5,$77,$05,$D8,$56,$1B,$8A
  DEFB $DF,$DA,$97,$8F,$00,$76,$66,$6C
  DEFB $E5,$27,$05,$68,$DD,$96,$48,$D0
  DEFB $66,$7E,$52,$83,$48,$D7,$88,$57
  DEFB $58,$8A,$5E,$4C,$51,$8D,$F4,$81
  DEFB $27,$8F,$00,$41,$00,$68,$5A,$5E
  DEFB $52,$5D,$5D,$26,$85,$0B,$56,$98
  DEFB $22,$77,$00,$76,$85,$95,$8D,$AF
  DEFB $5D,$A7,$8F,$00,$58,$E5,$46,$5F
  DEFB $00,$3A,$8D,$4B,$8A,$4C,$58,$5B
  DEFB $2B,$77,$00,$42,$00,$43,$00,$76
  DEFB $66,$71,$E5,$D5,$B6,$28,$B5,$0B
  DEFB $DA,$F6,$48,$67,$E5,$27,$05,$68
  DEFB $C2,$8A,$5E,$5B,$98,$13,$8D,$F4
  DEFB $83,$A8,$56,$9D,$9C,$78,$00,$68
  DEFB $D0,$63,$A8,$B5,$BD,$FD,$70,$5D
  DEFB $86,$09,$B5,$B2,$68,$52,$5D,$78
  DEFB $00,$68,$4B,$5E,$5D,$64,$83,$A8
  DEFB $B5,$BD,$FD,$70,$5D,$8D,$CD,$26
  DEFB $85,$25,$D7,$8F,$00,$68,$52,$83
  DEFB $47,$05,$D8,$D7,$88,$10,$DF,$48
  DEFB $66,$6C,$3A,$85,$69,$D9,$C8,$67
  DEFB $12,$78,$78,$78,$00,$68,$66,$6C
  DEFB $59,$B5,$B4,$DD,$7F,$71,$67,$66
  DEFB $71,$95,$16,$77,$57,$57,$57,$5F
  DEFB $00,$68,$DD,$96,$48,$66,$71,$3A
  DEFB $70,$55,$55,$8D,$4B,$80,$94,$D5
  DEFB $B5,$85,$98,$DD,$8D,$BE,$26,$89
  DEFB $55,$A9,$84,$F5,$25,$BA,$5D,$67
  DEFB $66,$6C,$3A,$83,$47,$05,$D8,$DA
  DEFB $76,$28,$DC,$D8,$D9,$C6,$2D,$BE
  DEFB $26,$89,$55,$A9,$67,$78,$00,$66
  DEFB $71,$DD,$96,$48,$E5,$27,$05,$68
  DEFB $C2,$8A,$5E,$5B,$98,$16,$20,$60
  DEFB $51,$02,$3A,$86,$0D,$9C,$5D,$85
  DEFB $69,$80,$95,$09,$5D,$78,$67,$66
  DEFB $6C,$3A,$86,$0D,$9C,$5D,$86,$05
  DEFB $10,$27,$57,$57,$87,$87,$87,$16
  DEFB $7F,$00,$DD,$96,$48,$3A,$70,$5B
  DEFB $98,$D6,$93,$A5,$B8,$58,$60,$57
  DEFB $78,$00,$8F,$00,$66,$6C,$52,$84
  DEFB $B9,$55,$52,$95,$F9,$83,$A6,$76
  DEFB $67,$13,$A6,$78,$D6,$D8,$4D,$52
  DEFB $4D,$8D,$BE,$B5,$D7,$8F,$00,$68
  DEFB $DD,$96,$48,$57,$58,$84,$C5,$1D
  DEFB $9C,$4C,$98,$75,$00,$68,$4B,$5E
  DEFB $5D,$64,$83,$A7,$05,$B9,$8D,$6D
  DEFB $8D,$CD,$26,$8D,$BE,$06,$75,$00
  DEFB $D6,$3A,$86,$66,$C4,$D5,$2A,$5D
  DEFB $DA,$F4,$C5,$D3,$16,$75,$85,$B4
  DEFB $DD,$AF,$B5,$B6,$28,$09,$56,$97
  DEFB $8F,$00,$66,$6C,$DD,$96,$48,$DB
  DEFB $EB,$5D,$70,$A8,$5A,$5E,$52,$5D
  DEFB $98,$52,$56,$DA,$79,$67,$66,$71
  DEFB $52,$70,$56,$8D,$D9,$64,$83,$A8
  DEFB $34,$70,$5D,$84,$D5,$88,$DB,$EB
  DEFB $5D,$67,$78,$00,$C2,$51,$26,$86
  DEFB $66,$CC,$6A,$80,$9D,$AC,$67,$66
  DEFB $71,$DA,$CA,$67,$78,$00,$66,$6C
  DEFB $60,$51,$02,$22,$71,$71,$67,$66
  DEFB $71,$22,$60,$51,$02,$71,$71,$67
  DEFB $00,$66,$6C,$DD,$A8,$4B,$98,$5B
  DEFB $52,$4D,$52,$4C,$5E,$55,$58,$5E
  DEFB $A7,$56,$76,$67,$1D,$9C,$8D,$AF
  DEFB $5D,$95,$B9,$A5,$D2,$68,$52,$4D
  DEFB $9B,$75,$67,$00,$66,$6C,$3A,$8B
  DEFB $5B,$DF,$D7,$05,$D8,$D1,$38,$DC
  DEFB $86,$76,$67,$1C,$CD,$F9,$85,$15
  DEFB $25,$05,$18,$DC,$A8,$3A,$67,$80
  DEFB $95,$BD,$9A,$78,$00,$5F,$52,$58
  DEFB $55,$DF,$D4,$C9,$86,$0D,$92,$85
  DEFB $09,$5D,$83,$A8,$57,$58,$60,$12
  DEFB $75,$00,$66,$71,$60,$B5,$D4,$C5
  DEFB $18,$07,$75,$67,$66,$6C,$D9,$18
  DEFB $4B,$B4,$D8,$55,$D9,$C5,$05,$EB
  DEFB $50,$98,$05,$12,$64,$85,$95,$59
  DEFB $BA,$97,$86,$7F,$00,$D5,$28,$CC
  DEFB $4F,$52,$61,$2B,$D5,$60,$75,$2A
  DEFB $78,$00,$CC,$DF,$98,$25,$DC,$A8
  DEFB $3A,$80,$9D,$CD,$78,$00,$CC,$DF
  DEFB $98,$D2,$78,$DC,$A8,$3A,$80,$9C
  DEFB $56,$67,$16,$48,$ED,$52,$67,$78
  DEFB $00,$DD,$98,$3A,$70,$5B,$98,$C2
  DEFB $8D,$7E,$DC,$87,$8F,$00,$52,$83
  DEFB $47,$05,$D8,$D7,$88,$13,$8D,$0D
  DEFB $82,$05,$2A,$78,$00,$51,$97,$0A
  DEFB $85,$65,$85,$F2,$68,$DF,$98,$4F
  DEFB $BA,$5D,$8D,$CA,$83,$A8,$09,$D9
  DEFB $67,$5F,$00,$00

OBJDES_TAB:
  DEFB $AE,$4C,$E5,$BE,$BE,$4D,$41,$6E
  DEFB $E5,$F4,$97,$84,$96,$F8,$E5,$3E
  DEFB $5E,$E5,$58,$48,$44,$65,$86,$09
  DEFB $55,$D4,$A8,$09,$E4,$CE,$BE,$AE
  DEFB $5D,$E5,$5E,$98,$E4,$BE,$55,$EB
  DEFB $E4,$CE,$54,$EA,$E5,$DE,$BE,$5B
  DEFB $64,$81,$6E,$AE,$4C,$E5,$B8,$EB
  DEFB $4D,$5F,$DF,$D5,$D5,$E5,$B9,$A7
  DEFB $86,$56,$58,$88,$83,$A8,$D4,$B8
  DEFB $DA,$B8,$AD,$FD,$5D,$8D,$69,$01
  DEFB $5A,$5E,$9A,$5D,$80,$9C,$58,$01
  DEFB $2C,$80,$B5,$B9,$D6,$85,$B8,$10
  DEFB $59,$58,$60,$95,$B8,$58,$5B,$4B
  DEFB $81,$65,$25,$DA,$85,$FB,$A5,$D8
  DEFB $D4,$E5,$0C,$48,$D1,$B5,$B5,$7A
  DEFB $78,$80,$9B,$4C,$51,$52,$95,$F9
  DEFB $80,$15,$6B,$61,$52,$56,$5E,$56
  DEFB $85,$95,$8D,$AF,$5D,$A8,$A4,$C5
  DEFB $85,$B9,$64,$8D,$A6,$85,$D5,$B9
  DEFB $BA,$5E,$5B,$9A,$84,$F5,$85,$E5
  DEFB $74,$D8,$56,$5E,$A5,$D8,$4B,$98
  DEFB $4C,$55,$9D,$9C,$A2,$B0,$8D,$BE
  DEFB $95,$25,$B8,$95,$F5,$25,$58,$64
  DEFB $8D,$A6,$85,$95,$E6,$36,$35,$59
  DEFB $A8,$D4,$1D,$4A,$80,$B1,$05,$85
  DEFB $B4,$B8,$5B,$95,$D5,$E5,$B5,$72
  DEFB $B0,$91,$0E,$DD,$27,$88,$10,$56
  DEFB $B6,$15,$25,$65,$E5,$68,$A4,$C5
  DEFB $85,$B9,$80,$64,$24,$54,$07,$86
  DEFB $56,$5F,$00,$00

