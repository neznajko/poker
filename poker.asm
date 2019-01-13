; 
; ))   )) ))   )))))   ))))  ))  )) )))))) )))))
; ((  (((((((  ((  (( ((  (( (( ((  ((     ((  ((
; ))   )))))   )))))  ))  )) ))))   ))))   )))))
; ((    (((    ((     ((  (( (( ((  ((     ((  ((
; ))     )     ))      ))))  ))  )) )))))) ))  ))
;
;-------0-------1-------2-------3-------4-------5-------6-------
;abel:  Inst    Opnds                   Cmnt
%include "communism.asm"
[section  .bss]
%define RANKZ   13 ; # card ranks
%define SUITZ    4 ; # card suits
%define MAXCRDZ 52 ; # max cards in deck
; deck nodes are cons from 4 bytes rank value, suit value,
; rank char, suit char for example 9c will be represented as
; |'c'|'9'| 0 | 7 | we are talking little endian here
%define DECKSIZ	MAXCRDZ*4 ; deck size in bytes
deck:		resb 	DECKSIZ
;; C):(.
; cards in play we allocate them statically rather than
; dinamically coz we don't need that excitement
gamecard:	resb 	DECKSIZ
; ptrs of gamecards where new cards are dealt
dashptr:	resd 	MAXCRDZ
playerz:	resb 	1 ; number of players
gamecardz:	resb 	1 ; number of cards in play
dashez:		resb 	1 ; number of dashes
scardz:		resb	1 ; number of scenario cards
%define	HNDCARDZ	5 ; number of hand cards
;; hand flags
flush:		resb 	1
wheel:		resb 	1
str8:		resb 	1
;; rank counters the first byte is the rank the second one is
;; the count
cntr:		resw 	HNDCARDZ
;; hand id
%define STR8FLUSH	8
%define FOUR		7
%define FULLHOUSE	6
%define FLUSH		5
%define STR8		4
%define THREE		3
%define TWOPAIRS	2
%define PAIR		1
%define HICARD  	0
;; hand rank structures first byte is the hand id next five
;; bytes are kickers' ranks
hndRnk:		resb 	HNDCARDZ + 1
maxHndRnk:	resb 	HNDCARDZ + 1
winHnd:		resb 	HNDCARDZ + 1
;; combinations
%define COMBOZ		7
%define COMBOSIZ	COMBOZ*4
combo:		resb	COMBOSIZ ; combo hand
cmb:	 	resb 	COMBOZ   ; combinations
%define	HNDSIZ		HNDCARDZ*4
hnd:		resb	HNDSIZ
;; number of wins per player
%define	MAXPLAYERZ	23
winz:		resd	MAXPLAYERZ	
;; rational number decimal expansion string
%define MAXSTR  128
qstr: 		resb	MAXSTR
[section .data]
dptr:		dd 	deck ; deck pointer
; initialization string the whole Monte Carlo is setup from this
; string it represents players' pocket cards and community cards
; the dashes are positions where new cards are dealt
istr:		db	"AsAh -Kc -- ---Qd-"
	times	MAXSTR - $ + istr	db	0
gamez:		dd 	100 ; # games
ranksym:	db 	"23456789TJQKA"
suitsym:	db 	"cdhs"
%define	IMCOLZ 	22 ; init message # columns
imsg:		db	"gamez:               ", 10
		db 	"playerz:             ", 10
		db 	"gamecardz:           ", 10
		db 	"dashez:              ", 10, 0
; ...
clr:		db 	27, "[34;1m", 0
rstclr: 	db 	27, "[0m", 0
;; wheel ranks in sorted hand (2, 3, 4, 5, A)
wheelRnk:	db 	0, 1, 2, 3, 12
;; strings for hand output
%define HSTRSIZ 37 ; hand string size
%define POKEPOZ 18 ; initial poke position (Jeff Duntemann)
handstr:	db 	"------HIGH-CARD-|---|---|---|---|---", 10
		db 	"-----------PAIR-|---|---|---|---|---", 10
		db 	"------TWO-PAIRS-|---|---|---|---|---", 10
		db 	"----------THREE-|---|---|---|---|---", 10
		db 	"-------STRAIGHT-|---|---|---|---|---", 10
		db 	"----------FLUSH-|---|---|---|---|---", 10
		db 	"-----FULL-HOUSE-|---|---|---|---|---", 10
		db 	"-----------FOUR-|---|---|---|---|---", 10	
		db 	"-STRAIGHT-FLUSH-|---|---|---|---|---", 10
;;
winstr:		db 	"...and the winners are: ", 0
[section .text]
%define	putchar	cdisplay
;	;	;	;	;	;	;
; _start 
; `     (atoi)
; `	(strlen)
; `--->	init
; `	`	(srnd)
; `	`----->	rstDeck
; `	`	`----->	setcard
; `	`----->	parser
; `	`	`----->	search
; `	`	`----->	infront
; `	`	`----->	rstdptr
; `	`----->	dmpDeck
; `	`	`	(sdisplay)
; `	`	`----->	dumpCard
; `	`		(cdisplay)
; `	`----->	dumpCards
; `		`----->	dumpCard
; `			(cdisplay)
; `		(itoa)
; `		(sdisplay)
; `--->	shuffle
; `		(getrnd)
; `---> deal
; `--->	wincnt
; `	`----->	dumpCards
; `	`----->	dmpDeck
; `	`----->	getHndRank
; `	`	`----->	sortRnks
; `	`	`----->	dumpCards
; `	`	`	(initcmb)
; `	`	`----->	eval
; `	`	`	`----->	flushck
; `	`	`	`----->	wheelck
; `	`	`	`----->	str8ck
; `	`	`	`----->	fillCntrs
; `	`	`	`----->	sortCntrs
; `	`	`----->	cmpHndRnk
; `     `       `       (nextcmb)
; `     `       `-----> dumpHand
; `	`			(sndisplay)                       
; `	`----->	cmpHndRnk
; `		(sdisplay)
; `		(idisplay)
; `		(cdisplay)
; `--->	rstdptr
; `--->	qtoa
;		(itoa)
;	(sdisplay)
;	(cdisplay)
;	(quit)
;
;   2: ))
;  c|:3x
; * |: P
;-------0-------1-------2-------3-------;-------5-------6-------
; tmpl: short description
;---------------------------------------------------------------
; in: entry conditions
;---------------------------------------------------------------
; out: exit conditions
;---------------------------------------------------------------
; modify: memory, registers etc.
;---------------------------------------------------------------
; notes: programmer's notes
;-------0-------1-------2-------3-------;-------5-------6-------
tmpl:                           	;
	nop                     	; gdb
	ret                     	; bye tmpl
;-------0-------1-------2------;3-------;-------5-------6-------
; setcard: card constructor
;---------------------------------------------------------------
; in: esi - card address
;     eax - rank
;     ebx - suit
;---------------------------------------------------------------
; out: nope
;---------------------------------------------------------------
; modify: [esi]
;---------------------------------------------------------------
; notes: void
;-------0-------1-------2-------3---;---4-------5-------6-------
setcard:                            ;
	nop                         ; gdb
	push 	edx                 ; backup
	mov	[esi], al	    ; set rank
	mov	[esi + 1], bl	    ; set suit
	mov	dl, [ranksym + eax] ; get rank and
 	mov	dh, [suitsym + ebx] ; suit symbols
	mov	[esi + 2], dl	    ; set card name
	mov	[esi + 3], dh	    ; ._.
	pop  	edx                 ; re-establish
	ret                         ; bye setcard
;-------0-------1-------2-------3---;---4-------5-------6-------
; rstDeck: reset deck
;---------------------------------------------------------------
; in:      nope
;---------------------------------------------------------------
; out:     negative
;---------------------------------------------------------------
; modify:  deck
;---------------------------------------------------------------
; notes:   naah
;-------0-------1-------2-------3-----;-4-------5-------6-------
rstDeck:                              ;
	nop                           ; gdb
	push	ebx		      ; backup
	push	esi		      ; 
	push	ecx		      ; 
	push	eax		      ; 
	mov	ebx, SUITZ	      ; suit (s)
	lea	esi, [deck + DECKSIZ] ; card pointer (p)
.Y:	dec	ebx		      ; s--
	sub	esi, 4		      ; p--
	mov	ecx, RANKZ - 1	      ; loop index
.Z:	lea	eax, [ecx - 1]	      ; rank
	call	setcard		      ; :)
	sub	esi, 4		      ; click next
	loop	.Z		      ; continuer a repeter
	mov	eax, RANKZ - 1	      ; Ace
	call	setcard		      ; ju-hu!
	cmp	ebx, 0		      ; =
	jg	.Y		      ; negative
	pop	eax		      ;
	pop	ecx		      ;
	pop	esi		      ;
	pop	ebx		      ; re-establish
	ret                           ; bye rstDeck
;-------0-------1-------2-------3-----;-4-------5-------6-------
; search: search deck
;---------------------------------------------------------------
; in: al - card rank (char)
;     ah - card suit (.. .)
;---------------------------------------------------------------
; out: ebx - card ptr
;---------------------------------------------------------------
; modify: none
;---------------------------------------------------------------
; notes: negative
;-------0-------1-------2------;3-------4-------5-------6-------
search:                        ; IwzEm
	nop                    ; =:-)~ gdb
	cld		       ;  : o  forward
	push	edi	       ; dB^"  backup
	push	ecx	       ;  : C
	mov	edi, [dptr]    ; }:')> str addr
	mov	ecx, MAXCRDZ*2 ; =:{{  count
	repnz	scasw	       ;  8 o  w00t
	lea	ebx, [edi - 4] ; q8 )  ye s!
	pop	ecx	       ;  : b
	pop	edi	       ; K:`o) re-establish
	ret                    ; d: /  bye search
;-------0-------1-------2------;3-------4-------5-------6-------
; infront: place card at deck front
;---------------------------------------------------------------
; in: ebx - card ptr
;---------------------------------------------------------------
; out: negative
;---------------------------------------------------------------
; modify: deck
;---------------------------------------------------------------
; notes: void
;-------0-------1-------2------;3-------4-------5-------6-------
infront:                       ;
	nop                    ; gdb               8 I
	std		       ; backward          8 L
	push	eax	       ; backup            8 1
	push	esi	       ;                   8 `
	push	edi	       ;                   8 l
	push	ecx	       ;                   8 ]
	mov	eax, [ebx]     ; put card in eax   8 )
	lea	esi, [ebx - 1] ; src str           8 /
	lea	edi, [esi + 4] ; dest str          8 o
	mov	ecx, ebx       ; get ze cnt	    8 O
	sub	ecx, deck      ; **                8 |
	rep	movsb	       ; w00t              8 ,
	mov	[deck], eax    ; finaly            8'"
	pop	ecx	       ;                   8 [
	pop	edi	       ;                   8 {
	pop	esi	       ;                   8 )
	pop	eax	       ;                   8 p
	cld		       ; re-establish	    8 _
	ret                    ; bye infront       8 U
;-------0-------1-------2------;3-------4-------5-------6-------
; rstdptr - reset deck pointer
;---------------------------------------------------------------
; entry conditions - scardz should be known
;---------------------------------------------------------------
; exit conditions - dptr is reset
;---------------------------------------------------------------
; modify - dptr
;---------------------------------------------------------------
; notes - negative
;-------0-------1-------2-------3---;---4-------5-------6-------
rstdptr:                            ;
	nop                         ; gdb
	push	eax		    ; backup
	movzx	eax, byte[scardz]   ; load scardz
	lea	eax, [deck + eax*4] ; yep!
	mov	[dptr], eax	    ; store eax	
	pop	eax		    ; re-establish
	ret                         ; bye rstdptr
;-------0-------1-------2-------3---;---4-------5-------6-------
; parser: parse istr
;---------------------------------------------------------------
; in: void
;---------------------------------------------------------------
; out: naah
;---------------------------------------------------------------
; modify: playerz, dashez, gamecardz, gamecard, dashptr, dptr
;         and deck
;---------------------------------------------------------------
; notes: nope
;-------0-------1-------2-------;-------4-------5-------6-------
parser:                         ;
	nop                   	; gdb
	push	esi	      	; backup
	push	eax	      	; /: r
	push	ebp	      	; l8 )
	push	edi	      	;
	push	ebx	      	;
	mov	esi, istr     	; init str ptr(c)
	xor	eax, eax      	; clear
	mov	ebp, gamecard 	; (p)
	mov	edi, dashptr  	; (d) S:{=
.Z:	mov	al, [esi]     	; al <- current char
	cmp	al, 0	      	; are we done?
	jz	.Y	      	; voila
	cmp	al, ' '	      	; ? q:O
	jnz	.X	      	; nah
	inc	byte[playerz] 	; inc number of players
	jmp	.W		; continue
.X:	cmp	al, '-'		; o-o ?
	jnz	.V		; negative
	inc	byte[dashez]	; inc number of dashes
	mov	[edi], ebp	; *d = p
	add	edi, 4		; next ptr
	jmp	.U		; follow me
.V:	inc	byte[scardz]	; inc number of scenario cards
	inc	esi		; c++
	mov	ah, [esi]	; al <- ze suit char
	call	search		; search deck
	call	infront		; put in front
	mov	ebx, [deck]	; ebx <- first card
	mov	[ebp], ebx	; gamecards
.U:	add	ebp, 4		; p++
.W:	inc	esi		; move to next char
	jmp	.Z		; come on
.Y:	mov	al, [scardz]	; : r
	add	al, [dashez]    ; : L
	mov	[gamecardz], al	; : o
	call	rstdptr		; l8^"L
	pop	ebx		; = /
	pop	edi		;
	pop	ebp		;
	pop	eax		;
	pop	esi		; re-establish
	ret                    	; bye parser
;-------0-------1-------2-------;-------4-------5-------6-------
; dumpCard  c):"-
;---------------------------------------------------------------
; in        esi - card address
;---------------------------------------------------------------
; out       negative
;---------------------------------------------------------------
; modify    nope
;---------------------------------------------------------------
; notes     no
;-------0-------1-------2------;3-------4-------5-------6-------
dumpCard:                      ;
	nop                    ; gdb
	push 	ecx            ; backup
	push 	edx            ;
	lea	ecx, [esi + 2] ; card ascii symbols
	cmp	byte[ecx], 0   ; ck if empty card
	jnz	.Z	       ; no
	putchar	'-'	       ; print a dash
	jmp	.Y	       ; let's go
.Z:	mov	edx, 2	       ; number of bytes
	call	sndisplay      ; have to change that name!
.Y:	pop 	edx            ;
	pop  	ecx            ; re-establish
	ret                    ; bye dumpCard
;-------0-------1-------2------;3-------4-------5-------6-------
; dmpDeck: dump deck
;---------------------------------------------------------------
; in: none
;---------------------------------------------------------------
; out: negative
;---------------------------------------------------------------
; modify: nope 
;---------------------------------------------------------------
; notes: colorize dptr's card
;-------0-------1-------2------;3-------;-------5-------6-------
dmpDeck:                       ;
	nop                    ; gdb
	push 	esi            ; backup
	push	ecx	       ; 
	push	ebx	       ; 
	push	edi	       ; 
	mov	esi, deck      ; card ptr
	mov	ecx, MAXCRDZ   ; loop cntr
	xor	ebx, ebx       ; cln cntr (column)
.Z:	cmp	esi, [dptr]    ; ck if (dptr)'s card
	jnz	.W	       ; naah
	mov	edi, esi       ; backup
	mov	esi, clr       ; print (dptr)'s card in
	call	sdisplay       ; color
	mov	esi, edi       ; re-establish
	call	dumpCard       ; : )
	mov	esi, rstclr    ; reset color
	call	sdisplay       ; wow!
	mov	esi, edi       ; re-establish
	jmp	.V	       ; yuhuu
.W:	call	dumpCard       ; Vitti'z on de phone...
.V:	cmp	ebx, RANKZ - 1 ; ck if last cln
	jb	.Y	       ; negative
	xor	ebx, ebx       ; clear
	putchar `\n`	       ; new line
	jmp	.X	       ; yuhuu!
.Y:	putchar ' '	       ; ...Primo
	inc	ebx	       ; next cln
.X:	add	esi, 4	       ; click next
	loop	.Z	       ; yjuhu!!	
	pop	edi	       ; \8'r
	pop	ebx	       ; |8'"\ 
	pop	ecx	       ; [ 8)
	pop  	esi            ; re-establish
	ret                    ; bye dmpDeck
;-------0-------1-------2------;3-------4-------5-------6-------
; dumpCards: CBl" 
;---------------------------------------------------------------
; in:     esi - cards' pointer
;         ecx - number of cards 
;---------------------------------------------------------------
; out:    negative
;---------------------------------------------------------------
; modify: nope 
;---------------------------------------------------------------
; notes:  pink vloid 
;-------0-------1-------2;------3-------4-------5-------6-------
dumpCards:             	 ;
	nop            	 ; gdb
	push 	esi    	 ; backup
	push	ecx	 ; loop
.Z:	call	dumpCard ; Vitti'z on de phone ...
	putchar ' '	 ; ... Primo
	add	esi, 4	 ; click next
	loop	.Z	 ; yjuhu!!
	putchar `\n`	 ; new line
	pop	ecx	 ; [ 8)
	pop  	esi      ; re-establish
	ret              ; bye dumpCards
;-------0-------1-------2;------3-------4-------5-------6-------
; init    initialize
;---------------------------------------------------------------
; in      none
;---------------------------------------------------------------
; out     nope
;---------------------------------------------------------------
; modify  playerz, dashez, gamecardz, gamecard, dashptr, dptr
;         and deck
;---------------------------------------------------------------
; notes   void
;-------0-------1-------2-------3-----;-4-------5-------6-------
init:   nop                           ; gdb
	pushad			      ; backup
;; initialize random number generator
	mov	eax, -1		      ; sys_time seed
	call	srnd		      ; init rnd gen
	call	rstDeck		      ; 
	call	parser		      ; read input
;; dump zome info
	call	dmpDeck		      ; yea!
	mov	esi, gamecard	      ; cards' addr
	movzx	ecx, byte[gamecardz]  ; number of cards
	call 	dumpCards	      ; dump zome cards
	sub	esp, 16		      ; allocate some space
	mov	ebp, esp	      ; output buffer
	std			      ; move backward
	movzx	eax, byte[dashez]     ; push in reverse order
	push	eax		      ; 4. dashez
	movzx	eax, byte[gamecardz]  ; B)
	push	eax		      ; 3. gamecardz
	movzx	eax, byte[playerz]    ; : o
	push	eax		      ; 2. playerz   
	mov	eax, [gamez]	      ; 8 .          __
	push	eax		      ; 1. gamez     `
;;	                                             o"
	mov	ebx, 1		      ; yep! or yup? Z
.Z:	pop	eax		      ; ze number
	mov	esi, ebp	      ; ze output buffer
	mov	edi, 10		      ; ze radix
	call	itoa		      ; Pronto ?!
	mov	ecx, edx	      ; 0) 
	lea	esi, [ebp + ecx - 1]  ; source str
	mov	eax, IMCOLZ	      ; =)
	mul	ebx		      ; >D 
	lea	edi, [imsg + eax - 2] ; destination str
	rep	movsb		      ; w00t   : E
	inc	ebx		      ; xD     : F
	cmp	ebx, 5		      ; 8|     : r
	jb	.Z		      ; 8\     : p
;;	                                       : )
	mov	esi, imsg	      ; finaly : o
	call	sdisplay	      ; yeah!
	cld			      ; clear direction flag
	lea	esp, [ebp + 16]	      ; balance the stack
	popad			      ; re-establish
	ret                           ; bye init
;-------0-------1-------2-------3-----;-4-------5-------6-------
; shuffle  shuflles the deck
;---------------------------------------------------------------
; in       void
;---------------------------------------------------------------
; out      negative
;---------------------------------------------------------------
; modify   deck
;---------------------------------------------------------------
; notes    nah
;-------0-------1-------2-------3---;---4-------5-------6-------
shuffle:                            ;
	nop                         ; gdb
	push	eax		    ; backup
	push	ebx		    ;
	push	ecx		    ;
	push	edx		    ;
	lea	ecx, [MAXCRDZ - 1]  ; loop idx
	mov	ebx, [dptr]	    ; [   :)
	sub	ebx, deck	    ; get dptr idx
	shr	ebx, 2		    ; shortcut (div by 4)
.Z:	cmp	ecx, ebx	    ; ecx ?> ebx
	jz	.Y		    ; let's go
	call	getrnd		    ; -> edx
	mov	eax, [deck + edx*4] ; exchange cards 
	xchg	eax, [deck + ecx*4] ; ecx with edx
	xchg	eax, [deck + edx*4] ; lB r
	dec	ecx		    ; *C: o
	jmp	.Z		    ; >|: /
.Y:	pop	edx		    ; re-establish
	pop	ecx		    ;
	pop	ebx		    ;
	pop	eax		    ;
	ret                         ; bye shuffle
;-------0-------1-------2-------3---;---4-------5-------6-------
; sortRnks: sort ranks
;---------------------------------------------------------------
; in: esi - cards base address
;     edi - number of cards
;---------------------------------------------------------------
; out: void
;---------------------------------------------------------------
; modify: [esi]...[esi+(edi-1)*4]
;---------------------------------------------------------------
; notes:   i.ru   +--------+   
;          > > > >| j <- 1 |      < < < 
;                 +--------+    v       ^
;                     v         v       ^
;   +-----------+-----------+   v       ^
;   | R <- R[j] | K <- K[j] |< <        ^ ye_!
;   +-----------+----------++      +---------+ no
;               | i <- j-1 |       | j <=? N |> > > > > >
;               +----------+       +---------++        de
;                     v            | j <- j+1 |
;               +------------+ yea +----------+--+
;          > > >| K[i] <=? K |> > >| R[i+1] <- R |
;         ^     +------------+     +-------------+
;         ^           v nope            ^
;         ^     +----------------+      ^
;         ^     | R[i+1] <- R[i] |      ^
;         ^     +------------+---+      ^
;         ^     | i <- i - 1 |          ^
;         ^     +--------+---+          ^
;          < < <| i <? 0 |> > > > > > > ^
;         no    +--------+            yea
;-------0-------1-------2-------3-------4;------5-------6-------
sortRnks:				 ;
	nop				 ; gdb
	push    eax			 ; backup
	push	ebx			 ;
	push	ecx			 ;
	push	edx			 ;	
	mov	ecx, 1			 ; j
.Z:	mov	edx, [esi + (ecx)*4]	 ; R
	lea	ebx, [ecx - 1]		 ; i
.Y:	mov	eax, [esi + (ebx)*4]	 ; R[i]
	cmp	al, dl			 ; K[i] <= K?
	jle	.X			 ; yeah!
	mov	[esi + (ebx + 1)*4], eax ; sifting R[i+1] <- R[i]
	dec	ebx			 ; i--
	cmp	ebx, 0			 ; i <? 0
	jge	.Y			 ; naah
.X:	mov	[esi + (ebx + 1)*4], edx ; inserting R[i+1] <- R
	inc	ecx			 ; j++
	cmp	ecx, edi		 ; j <? # cards
	jb	.Z			 ; yeah!
	pop	edx			 ;
	pop	ecx			 ;
	pop	ebx			 ;
	pop	eax			 ; re-establish
	ret				 ; bye sortRnks
;-------0-------1-------2-------3-------4;------5-------6-------
; flushck: flush check
;---------------------------------------------------------------
; in: ebx - hand addr
;---------------------------------------------------------------
; out: void
;---------------------------------------------------------------
; modify: flush
;---------------------------------------------------------------
; notes: nope
;-------0-------1-------2-------3-------4---;---5-------6-------
flushck:                           	    ;
	nop                     	    ; gdb
	push	eax			    ; backup
	push	ecx			    ;
	mov	ecx, HNDCARDZ		    ;
	mov	al, [ebx + (ecx - 1)*4 + 1] ;
	dec	ecx			    ;
.Z:	cmp	al, [ebx + (ecx - 1)*4 + 1] ;
	jnz	.Y			    ;
	loop	.Z			    ;
	mov	al, 1			    ;
	jmp	.X			    ;
.Y:	xor	al, al			    ;
.X:	mov	[flush], al		    ;	
	pop	ecx			    ;
	pop	eax			    ; re-establish
	ret                     	    ; bye flushck
;-------0-------1-------2-------3-------4---;---5-------6-------
; wheelck: short description
;---------------------------------------------------------------
; in: ebx - hand ptr (the hand should be sorted)
;---------------------------------------------------------------
; out: void
;---------------------------------------------------------------
; modify: wheel
;---------------------------------------------------------------
; notes: negative
;-------0-------1-------2-------3-------4--;----5-------6-------
wheelck:                           	   ;
	nop                     	   ; gdb
	push	eax			   ;
	push	ecx			   ;
	mov	ecx, HNDCARDZ		   ; j+1
.Z:	mov	al, [ebx + (ecx - 1)*4]	   ; Rnk[j]
	cmp	al, [wheelRnk + (ecx - 1)] ; Rnk[j] =? wheelRnk[j]
	jnz	.Y			   ; naah
	loop	.Z			   ;
	mov	al, 1			   ;
	jmp	.X			   ;
.Y:	xor	al, al			   ;
.X:	mov	[wheel], al		   ; ye_!
	pop	ecx			   ;
	pop	eax			   ;
	ret                     	   ; bye wheelck
;-------0-------1-------2-------3-------4--;----5-------6-------
; str8ck: straight check
;---------------------------------------------------------------
; in: ebx - hand ptr (the hand should be sorted)
;---------------------------------------------------------------
; out: none
;---------------------------------------------------------------
; modify: str8
;---------------------------------------------------------------
; notes: naah
;-------0-------1-------2-------3-------;-------5-------6-------
str8ck:                           	;
	nop                     	; gdb
	push	eax			;
	push	ecx			;
	mov	ecx, HNDCARDZ-1		;
.Z:	mov	al, [ebx + (ecx - 1)*4]	; R[j]
	inc	al			; 
	cmp	al, [ebx + (ecx)*4]	; R[j]+1 =? R[j+1]
	jnz	.Y			;
	loop	.Z			;
	mov	al, 1			;
	jmp	.X			;
.Y:	xor	al, al			;
.X:	mov	[str8], al		;
	pop	ecx			;
	pop	eax			;
	ret                     	; bye str8ck
;-------0-------1-------2-------3-------;-------5-------6-------
; fillCntrs: fill counters
;---------------------------------------------------------------
; in: ebx - hand ptr(sorted) 
;---------------------------------------------------------------
; out: cntr 
;---------------------------------------------------------------
; modify: cntr
;---------------------------------------------------------------
; notes: void
;-------0-------1-------2-------3-------4;------5-------6-------
fillCntrs:                           	 ;
	nop                     	 ; gdb
	push	eax			 ;
	push	ecx			 ;
	push	edi			 ;
	push	esi			 ;
;;[s0 init]
	xor	ax, ax			 ; value
	mov	ecx, HNDCARDZ		 ; count
	mov	edi, cntr		 ; destination
	cld				 ; direction
	rep	stosw			 ; w00t
	xor	esi, esi		 ; i cntr idx
	mov	ecx, HNDCARDZ - 1	 ; j hand idx
;;[s1 set rank]
.Z:	mov	al, [ebx + (ecx)*4]	 ; Rnk[j]
	mov	[cntr + (esi)*2], al	 ;
;;[s2 inc]
.Y:	inc	byte[cntr + (esi)*2 + 1] ; ze counter
;;[s4 are we done?]
	dec	ecx			 ; j--
	jl	.X			 ; ye_!
;;[s3 cmp]
	cmp	al, [ebx + (ecx)*4]	 ; Rnk[j] =? Rnk[j-1]
	jz	.Y			 ;
	inc	esi			 ; i++
	jmp	.Z			 ;
.X:	pop	esi			 ;
	pop	edi			 ;
	pop	ecx			 ;
	pop	eax			 ;
	ret                     	 ; bye fillCntrs
;-------0-------1-------2-------3-------4;------5-------6-------
; sortCntrs: sort counters
;---------------------------------------------------------------
; in: void
;---------------------------------------------------------------
; out: cntr
;---------------------------------------------------------------
; modify: cntr
;---------------------------------------------------------------
; notes: modified sortRnks algorithm
;-------0-------1-------2-------3-------4--;----5-------6-------
sortCntrs:                           	   ;
	nop                     	   ; gdb
	pushad				   ; backup
	mov	esi, cntr		   ; records ptr
	mov	edi, HNDCARDZ		   ; # records
	mov	ecx, 1			   ; j
.Z:	cmp	byte[esi + (ecx)*2 + 1], 0 ; K[j] =? 0 (zero cnt)
	jz	.W			   ; yea!
	mov	dx, [esi + (ecx)*2]	   ; R
	lea	ebx, [ecx - 1]		   ; i
.Y:	mov	ax, [esi + (ebx)*2]	   ; R[i]
	cmp	ah, dh			   ; K[i] <? K
	jge	.X			   ; naah!
	mov	[esi + (ebx + 1)*2], ax	   ; sifting R[i+1] <- R[i]
	dec	ebx			   ; i--
	cmp	ebx, 0			   ; i <? 0
	jge	.Y			   ; naah
.X:	mov	[esi + (ebx + 1)*2], dx	   ; inserting R[i+1] <- R
	inc	ecx			   ; j++
	cmp	ecx, edi		   ; j <? # cards
	jb	.Z			   ; yeah!
.W:	popad				   ; re-establish
	ret                     	   ; bye sortCntrs
;-------0-------1-------2-------3-------4--;----5-------6-------
; dmpCntrs: dump counters
;---------------------------------------------------------------
; in: none
;---------------------------------------------------------------
; out: void
;---------------------------------------------------------------
; modify: nah
;---------------------------------------------------------------
; notes: negative
;-------0-------1-------2-------3;------4-------5-------6-------
dmpCntrs:                        ;
	nop                      ; gdb
	pushad            	 ; backup registers
	mov 	ebx, cntr     	 ; pass counter's address to ebx
	mov 	ecx, HNDCARDZ  	 ; number of loops
	mov 	edi, 10       	 ; 10-base system
	xor	eax, eax	 ; clear
	mov	esi, ranksym	 ; what is this?
.Start:
	cmp 	byte[ebx + 1], 0 ; iz it a zero count?
	jz 	.Finish       	 ; let's go
	mov 	al, [ebx]  	 ; rank
	mov 	al, [esi + eax]  ; rank symbol
        putchar eax              ; C8C
	inc	ebx              ; click next
	putchar ' '              ; ye_!
	mov 	al, [ebx]    	 ; count
	call 	idisplay         ; :)
	inc 	ebx              ; click next 
	putchar `\n`             ; ._.
	loop 	.Start		 ; follow me
.Finish:
	popad 			 ; re-establish registers
	ret                      ; bye dmpCntrs
;-------0-------1-------2-------3;------4-------5-------6-------
; eval: evaluates a hand
;---------------------------------------------------------------
; in: ebx - hand's address
;     edi - hand rank buffer
;---------------------------------------------------------------
; out: hand is evaluated and set at [edi]
;---------------------------------------------------------------
; modify: flush, wheel, str8
;---------------------------------------------------------------
; notes: hand should be sorted
;-------0-------1-------2-------3-------4-;-----5-------6-------
eval:                           	  ;
	nop                     	  ; gdb
	push	eax		          ; backup
	push	ecx		          ; 
	push    edx                       ;  
	push	esi			  ; 
;; [e1. initialize hand rank buffer]
	mov	byte[edi], HICARD         ; set default id
	push	edi			  ; backup
	mov	al, -1                    ; fill kickers with -1
	inc	edi  			  ; destination
	mov	ecx, HNDCARDZ         	  ; count
	cld				  ; direction flag
	rep	stosb		          ; w00t
	pop	edi			  ; re-establish
;; [e2. set kicker[0]]
	lea	edx, [HNDCARDZ - 1]       ; last index (z)
	mov 	al, [ebx + (edx)*4]       ; al <- hnd[z].rank
	mov	byte[edi + 1], al	  ; kicker[0] <- al
;; [e3. ck flags]
	call	flushck		          ; flush check
	call	wheelck		          ; wheel check
	call	str8ck		          ; str8 check
;; [e4. str8 or flush?]
	mov	al, [str8]		  ; str8
	or	al, [wheel]		  ; or wheel?
	jz	.Flush			  ; negative
	cmp	byte[wheel], 1		  ; chg kicker
	jnz	.Str8Flush		  ; negative
	mov	byte[edi + 1], 3	  ; kicker[0] <- five
.Str8Flush:
	cmp	byte[flush], 1		  ; a flush???
	jnz	.Str8			  ; not likely
	mov	byte[edi], STR8FLUSH	  ; roger
	jmp	.Z			  ; peace 
.Str8:	mov	byte[edi], STR8		  ; yea
.Z:	jmp	.Y			  ; take it easy doc
.Flush: cmp	byte[flush], 1		  ; iz it???
	jnz	.X			  ; nay
	mov	byte[edi], FLUSH	  ; yup
	mov	ecx, edx		  ; ecx <- z (j)
	xor	esi, esi		  ; clear (z-j)
.W:	mov	al, byte[ebx + (esi)*4]   ; al <- hnd[z-j].rnk
	mov	byte[edi + (ecx) + 1], al ; kicker[j] <- al
	inc	esi			  ; click next
	loop	.W			  ; come on
;; [e5. counters]
.X:	call	fillCntrs    		  ; fill counters
	call	sortCntrs                 ; sort counters
;; [e6. fill kickers]
	mov	ecx, 0			  ; loop index (j)
.V:    	cmp     ecx, HNDCARDZ             ; ecx =? HNDCARDZ
	jz      .U			  ; aye aye
	mov     ax, [cntr + (ecx)*2]      ; ax <- cntr[j]
	cmp     ah, 0                     ; zero counter?
	jz      .U	                  ; affirmative
	mov	byte[edi + (ecx) + 1], al ; kicker[j] <- rnk
        inc     ecx                       ; click next
        jmp     .V                     	  ; follow me
;; [e7. four, full house, three ...]
.U:	mov     al, [cntr + 1]            ; al <- cntr[0].n
	cmp	al, 4			  ; four of a kind?
	jnz	.FullHouse		  ; go fish
	mov	byte[edi], FOUR		  ; update hrank.id
	jmp	.Y			  ; take it easy Doc
.FullHouse:                               ; ... or three
	cmp     al, 3			  ; ?
	jnz	.TwoPairs		  ; negative
	mov	byte[edi], THREE	  ; set hrank.id
	mov	ah, [cntr + 3]		  ; ah <- cntr[1].n
	cmp	ah, 2			  ; full house ck
	jnz	.Y			  ; three of a kind
	mov	byte[edi], FULLHOUSE	  ; update hrank.id
	jmp	.Y			  ; au revoir
.TwoPairs:			 	  ;
	cmp	al, 2			  ; any pairs?
	jnz	.Y			  ; high card
	mov	byte[edi], PAIR		  ; hrank.id <- PAIR
	mov	ah, [cntr + 3]		  ; ah <- cntr[1].n
	cmp	ah, 2			  ; second pair?
	jnz	.Y			  ; a pair
	mov	byte[edi], TWOPAIRS	  ; hrank.id <- TWOPAIRS
.Y:	pop	esi			  ;
	pop	edx		          ;
	pop	ecx		          ;
	pop	eax		          ; re-establish
	ret                     	  ; bye eval
;-----------------------------------------;-------------
; dumpHand: output hand id and kickers
;-------------------------------------------------------
; in: edi - hand address
;-------------------------------------------------------
; out: none
;-------------------------------------------------------
; modify: void
;-------------------------------------------------------
; notes: negative
;---------------------------------;---------------------
dumpHand:                         ;
	nop                       ; gdb
	push  eax                 ; backup
	push  edx                 ;
	push  ebx                 ;
	push  ecx		  ;
;;	[d0. set poke position]
	movzx eax, byte[edi]      ; eax <- id
	mov   edx, HSTRSIZ        ; 
	mul   edx                 ; eax <- handstr offset
	mov   edx, handstr        ; adjust edx to inital ...
	add   edx, eax            ; 
	mov   ecx, edx            ; (sndisplay)
	add   edx, POKEPOZ        ; ... poking pozition
;;	[d1. poke loop]
	xor   eax, eax		  ; clear
	mov   ebx, 1              ; first kicker
.POKE:  mov   al, [edi + ebx]     ; al <- kicker's rank
	cmp   al, -1              ; are we done?
	jz    .FIN                ; yup!
	mov   al, [ranksym + eax] ; rank symbol
	mov   byte[edx], al       ; poke
	inc   ebx                 ; next kicker
	cmp   ebx, HNDCARDZ       ; are we done?
	ja    .FIN                ; yup!
	add   edx, 4     	  ; move to next pozition
	jmp   .POKE               ; once again
;;      [d2. output]
.FIN:	mov   edx, HSTRSIZ        ; 
	call  sndisplay           ;
	pop   ecx		  ; re-establish
	pop   ebx                 ;
	pop   edx                 ;
	pop   eax                 ;
	ret                       ; bye dumpHand
;-------0-------1-------2-------3-;-----4-------5-------6-------
; cmpHndRnk  compare two hand ranks
;---------------------------------------------------------------
; -P         esi, edi (ptrs to hand ranks)
;---------------------------------------------------------------
;            eax   0 esi = edi
; P-               1 esi > edi
;                  2 esi < edi
;---------------------------------------------------------------
; calls      none
;---------------------------------------------------------------
; notes      void
;-------0-------1-------2-------3-;-----4-------5-------6-------
cmpHndRnk:                        ;
	nop                       ; gdb
	push	ebx		  ; backup
	push	ecx		  ;
	xor	eax, eax	  ; clear output
	xor	ecx, ecx	  ; index
.C:	mov	bl, [esi + (ecx)] ;
	mov	bh, [edi + (ecx)] ;
	cmp	bl, bh		  ;
	jg	.G		  ;
	jl	.L		  ;
	inc	ecx		  ;
	cmp	ecx, HNDCARDZ	  ;
	jle	.C		  ;
	jmp	.Q		  ;
.G:	mov	eax, 1		  ;
	jmp	.Q		  ;
.L:	mov	eax, 2		  ;
.Q:	pop	ecx		  ; re-establish			
	pop	ebx		  ;
	ret                       ; bye cmpHndRnk
;-------0-------1-------2-------3-;-----4-------5-------6-------
; getHndRank: get hand rank
;---------------------------------------------------------------
; in: ecx - player's index
;---------------------------------------------------------------
; out: maxHndRnk
;---------------------------------------------------------------
; modify: hndRnk, maxHndRnk
;---------------------------------------------------------------
; notes: card size is a double word (4 bytes)
;-------0-------1-------2-------3-------4--;----5-------6-------
getHndRank:                           	   ;
	nop                     	   ; gdb
	pushad				   ; backup
;;	[g0. set combo hand]
	lea	esi, [gamecard + (ecx)*8]  ; player's pocket
	mov	edi, combo		   ; 
	;; copy ninja Kakashi
	cld				   ; forward
	mov	ecx, 2			   ; number of double words
	rep 	movsd			   ; w00t
	;; we have the pocket now community cards
	mov	cl, [playerz]		   ;
	lea	esi, [gamecard + (ecx)*8]  ; community cards
	mov	ecx, 5			   ; ye-!
	rep	movsd			   ; w..t
;;	[g1. sort combo]
	mov	esi, combo		   ;
	mov	edi, COMBOZ		   ;
	call	sortRnks		   ;
%ifdef	DEBUG
	mov	ecx, edi		   ;
	call	dumpCards		   ;
%endif
;;	[g2. initialize]
	mov	ebx, cmb		   ; ze combinations
	mov	edx, HNDCARDZ		   ; dl
	mov	 dh, COMBOZ		   ; 
	call	initcmb			   ; yeah!
	mov	edi, maxHndRnk		   ; max rank hand
	mov	al, -1			   ;
	mov	ecx, 1 + HNDCARDZ	   ;
	cld				   ;
	rep	stosb			   ;
;;	[g3. loop through all combinations]
.G3:
;;	[g4. set up a hand]
	mov	esi, hnd		   ;
	mov	ecx, HNDCARDZ		   ;
.Z:	movzx	eax, byte[cmb + (ecx - 1)] ; c[j]
	mov	edi, [combo + (eax)*4]	   ;
	mov	[esi + (ecx - 1)*4], edi   ; hnd[j] <- combo[c[j]]
	loop	.Z			   ;
;; 	[g5. eval hand]
	mov	ebx, hnd		   ;
	mov	edi, hndRnk		   ;
	call	eval			   ;
;;	[g6. set max rank hand]
	mov	esi, hndRnk		   ;
	mov	edi, maxHndRnk		   ;
	call	cmpHndRnk	 	   ;
	cmp	eax, 1			   ; hndRnk >? maxHndRnk
	jnz	.W			   ; naah
	mov	ecx, HNDCARDZ + 1	   ;
	rep	movsb			   ; w00t
.W:
	mov	ebx, cmb		   ;
	call	nextcmb			   ; next cmb
	jnz	.G3			   ; ,,
	mov	edi, maxHndRnk		   ;
%ifdef	DEBUG
	call	dumpHand		   ;
%endif 	
	popad				   ; re-establish
	ret                     	   ; bye getHndRank
;-------0-------1-------2-------3-------4--;----5-------6-------
; wincnt  win count
;---------------------------------------------------------------
; in      void
;---------------------------------------------------------------
; out     void
;---------------------------------------------------------------
; modify  winz
;---------------------------------------------------------------
; notes   wtf?
;-------0-------1-------2-------3-----;-4-------5-------6-------
wincnt: nop                           ; gdb
	pushad			      ; backup
%ifdef	DEBUG	
	mov	esi, gamecard	      ; cards addr
	movzx	ecx, byte[gamecardz]  ; number of cards
	call 	dumpCards	      ; dump zome cards
	call	dmpDeck		      ; dump ze deck
%endif
;; [W0. Init] coz of the split win we save winners az bit
;; positions in ebp
	mov	ebp, 1		      ; w
	xor	ecx, ecx	      ; first player
	call	getHndRank	      ; output --> maxHndRnk
	mov	esi, maxHndRnk	      ; copy Ninja Kakashi
	mov	edi, winHnd	      ; ...
	mov	ecx, HNDCARDZ + 1     ;
	cld			      ;
	rep	movsb		      ; w00t
	mov	esi, maxHndRnk	      ; restore
	mov	edi, winHnd	      ; 
;; [W1. Loop] now we loop over the remaining players to get
;; the winners
	mov	ecx, 1		      ; second player
	movzx	edx, byte[playerz]    ; edx <- number of players
;; [W2. Switch]
.Z:	call 	getHndRank	      ; ye_!
	call	cmpHndRnk	      ; output at eax
	cmp	eax, 2		      ; win > max
	jz	.Next		      ; continue
	cmp	eax, 1		      ; max > win
	jnz	.Split		      ;
	push	ecx		      ; copy Ninja Kakashi
	mov	ecx, HNDCARDZ + 1     ;
	rep	movsb		      ; w00t
	mov	esi, maxHndRnk	      ; 
	mov	edi, winHnd	      ; 
	pop	ecx		      ; restore
	mov	ebp, 1		      ;
	shl	ebp, cl		      ;	
	jmp	.Next		      ;
.Split: mov	eax, 1		      ;
	shl	eax, cl		      ;
	or	ebp, eax	      ;
.Next:	inc	ecx		      ; o_o
	cmp	ecx, edx	      ; <?
	jb	.Z		      ; ..
;; [W3. Inc]
%ifdef	DEBUG	
	mov	esi, winstr	      ;
	call	sdisplay	      ;
	mov	eax, ebp	      ;
	mov	edi, 2		      ;
	call	idisplay	      ;
	putchar `\n`		      ;
%endif
	xor	ecx, ecx	      ; j
.Y:	test	ebp, 1		      ; ck if winner
	jz	.Clik		      ; naah
	inc	dword[winz + (ecx)*4] ; winz[j]++
.Clik:	inc	ecx		      ;
	cmp	ecx, edx	      ;
	jz	.Exit		      ;
	shr	ebp, 1		      ; next player
	jmp	.Y		      ;
.Exit:  popad			      ; re-establish
	ret                           ; bye wincnt
;-------0-------1-------2-------3-----;-4-------5-------6-------
; qtoa: rational number to ascii (decimal expansion)
;---------------------------------------------------------------
; start: eax(m), ebx(n), esi(output string), edi(precision)
;---------------------------------------------------------------
; finish: m/n decimal expansion at [esi]
;---------------------------------------------------------------
; modify: [esi]
;---------------------------------------------------------------
; notes: nope
;-------0-------1-------2-------3----;--4-------5-------6-------
qtoa:                                ;
	nop                          ; gdb
	push 	eax                  ; backup
	push	ecx		     ;
	push	edx		     ;
	push	esi		     ;
	cmp	eax, 0		     ;
	jge	.D1		     ;
	mov	byte[esi], '-'	     ;
	neg	eax		     ;
	inc	esi		     ;
.D1:	xor	edx, edx	     ;
	div	ebx		     ; q <- eax, r <- edx
	push	edi		     ; backup
	push	edx		     ;
	mov	edi, 10		     ; radix
	call	itoa		     ; :) edx <- # bytes
	add	esi, edx	     ; inc str ptr
	pop	edx		     ;
	pop	edi		     ; re-establish
	xor	ecx, ecx	     ; expansion index j
.D2:	cmp	ecx, edi	     ; zero precision?
	jz	.Z		     ;
.D3:	mov	byte[esi], '.'	     ;
.D4:	inc	ecx		     ; yeah!
.D5:	cmp	ecx, edi	     ; prc ck
	jg	.Z		     ;
	mov	eax, edx	     ; <- r
	mov	edx, 10		     ;
	mul	edx		     ; m <- r * 10
	div	ebx		     ; q, r
	add	eax, '0'	     ; ascii
	mov	[esi + (ecx)], al    ;
	jmp	.D4		     ; 
.Z:	mov	byte[esi + (ecx)], 0 ; zero byte
	pop	esi		     ;
	pop	edx		     ;
	pop	ecx		     ;
	pop  	eax                  ; re-establish
	ret                          ; bye qtoa
global _start
;; not so versatile as C but we can run the program with 
;; arguments like ./poker 1000 "QhQs -- -----" where first
;; argument is the number of games (gamez) and the second
;; one iz the initialization string (istr)
;-------0-------1-------2-------3-----;-4-------5-------6-------
_start:	nop			      ; gdb
	pop	ecx		      ; argc
	cmp	ecx, 1		      ; ck if any args
	jz	.X		      ; negative
;; get gamez
	mov	esi, [esp + 4]	      ; argv[1] 
	mov	edi, 10		      ; radix
	call	atoi		      ; eax <- ze integer
	mov	[gamez], eax	      ; set gamez
;; get istr
	cmp	ecx, 3		      ; ck for istr
	jb	.X		      ; nah
	mov	esi, [esp + 8]	      ; argv[2]
	call 	strlen		      ; edx <- bytez
	mov	ecx, edx	      ; ze cnt
	mov	edi, istr	      ; dest string
	cld			      ; increment
	rep	movsb		      ; w00t
	mov	byte[edi], 0	      ; add zero byte
.X:			; ¿!! test zone !!!
	call	init 
	xor	ebx, ebx	      ; games cntr
	movzx	edx, byte[dashez] ; number of cards to deal
.Shfl:	nop
	call	shuffle ;
	mov	esi, [dptr] ; card itor
.Deal:	lea	esi, [esi + (edx)*4] ; we deal backward
	cmp	esi, deck + DECKSIZ  ; if there are enough
	jg	.Rst ; cards left in the deck
	call	deal ;
	mov	[dptr], esi ; update deck pointer
	call	wincnt
	inc	ebx ; inc number of games
	cmp	ebx, [gamez] ; ck if we are done
	jz	.T ; yep!
	jmp	.Deal ; 
.Rst:	call	rstdptr ; reset deck pointer
	jmp	.Shfl ;
.T:	;; print results
	xor	ecx, ecx              ;
	mov	ebx, [gamez]          ;
	mov	esi, qstr             ;
	mov	edi, 4                ;
.PrRes:	mov	eax, [winz + (ecx)*4] ;
	mov	edx, 100              ;
	mul	edx                   ; 
	call	qtoa                  ;
	call	sdisplay              ;
	putchar `\n`                  ;
	inc	ecx                   ;
	cmp	cl, [playerz]         ;
	jb	.PrRes                ;
.Exit	call	quit		      ; bye
;-------0-------1-------2-------3-----;-4-------5-------6------;-
; in    : esi   - card address  , edx   - number of dashes     ;;-
;-------5-------2-------1-------0-------6-------3-------4------;-
; out   : n       o       p       e                            ;;-
;-------3-------6-------5-------4-------2-------1-------0------;-
 ;-------2-------1-------0-------3-------6---;---4-------5------;-
deal:	nop 			             ; gdb
	mov	edi, esi		     ; preserve esi
	mov	ecx, edx		     ; loop cntr
.A:	lea	edi, [edi - 4]               ; move to prev card
	mov	eax, [edi]                   ; load card to eax
	mov	ebp, [dashptr + (ecx - 1)*4] ; load gamecard ptr to ebp
	mov	[ebp], eax		     ; copy Ninja Kakashi
	loop	.A			     ; come on
	ret 			             ; bye deal
