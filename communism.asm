[section  .bss]
;; 32 bit random numbers
MAXRND:  equ  0x7fffffff
nextRnd: resd 1
[section .data]
hexDigit: db "0123456789abcdef"
[section .text]
;---------------------------------------------------------------;
; quit: ends the party                                          ;
;---------------------------------------------------------------;
; calls: sys_exit                                               ;
;-----------------------;-------------------------------;-------;
quit:	mov eax, 1      ; sys_exit                      ;
	mov ebx, 0      ; success                       ;
	int 0x80        ; bye :)                        ;
;-------1-------2-------;-------4-------5-------6-------;
; strlen: gets the length of a zero terminated string   ;
;-------------------------------------------------------;
; input: esi - string address                           ;
;-------------------------------------------------------;
; output: edx                                           ;
;---------------------;---------------------------------;
strlen:	push eax      ; backup registers                ;  
	push ecx      ;                                 ; 
	push edi      ;                                 ; 
	mov eax, 0    ; scan for zero byte              ;
	mov edi, esi  ; copy string address to edi      ;
	mov ecx, 0xff ; max search                      ;
	cld           ; clear direction flag            ;
	repne scasb   ; w00t                            ;
	sub edi, esi  ; edi <- number of bytes plus one ;
	lea edx, [edi - 1] ; edx <- number of bytes     ;
	pop edi       ;                                 ;   
	pop ecx       ;                                 ;  
	pop eax       ; re-establish registers          ;  
	ret           ; bye :)                          ;
;---------------------;---------------------------------;
; sndisplay: displays n bytes from a string to stdout   ;
;-------------------------------------------------------;
; input: ecx - string address                           ;
; 	 edx - number of bytes                          ;
;-------------------------------------------------------;
; calls: sys_write                                      ;
;-----------------------;-------------------------------;
sndisplay:	        ;                               ;
	push eax        ; backup registers              ;
	push ebx        ;                               ;
	mov eax, 4      ; sys_write                     ;
	mov ebx, 1      ; stdout                        ;
	int 0x80        ; syscall                       ;
	pop ebx         ; re-estabilish registers       ;
	pop eax         ;                               ;
	ret             ; bye                           ;
;-----------------------;-------------------------------;
; sdisplay: displays a zero terminated string to stdout ;
;-------------------------------------------------------;
; input: esi - string address                           ;
;-------------------------------------------------------;
; calls: strlen, sndisplay                              ;
;----------------------;--------------------------------;
sdisplay:              ;                                ;
	push edx       ; backup registers               ;
	push ecx       ;                                ;
	call strlen    ; wow!                           ;
	mov ecx, esi   ; input of sndisplay             ;
	call sndisplay ; what is this?                  ;
	pop ecx        ;                                ;
	pop edx        ; re-establish registers         ;
	ret            ; bye                            ;
;----------------------;--------------------------------;
; cdisplay: displays a character to stdout              ;
;-------------------------------------------------------;
; calls: sndisplay                                      ;
;-------------------------------------------------------;
; note: use 'backquotes' for escape sequences: `\n`     ;
;----------------------;--------------------------------;
%macro cdisplay 1      ;                                ;
	push ecx       ; backup registers               ;
	push edx       ;                                ;
	push %1        ; push the character to stack    ;
	mov ecx, esp   ; pass its address to ecx        ;
	mov edx, 1     ; one character long string      ;
	call sndisplay ; yeah!                          ;
	add esp, 4     ; balance the stack              ;
	pop edx        ;                                ;
	pop ecx        ; re-establish registers         ;
%endmacro              ;                                ;
;----------------------;--------------------------------;
; itoa: integer to ascii                                ;
;-------------------------------------------------------;
; input: eax - an integer number                        ;
;        esi - the address of output buffer             ;
;        edi - radix                                    ;
;-------------------------------------------------------;
; output: edx - number of bytes                         ;
;--------------------;----------------------------------;
itoa:   nop          ;                                  ;
	push ecx     ; backup registers                 ;
	push ebp     ;                                  ;
	push eax     ;                                  ;
	mov ecx, 0   ; digit counter                    ;
	mov ebp, esi ; buffer iterator                  ;
	cmp edi, 10  ; avoid sign check for non 10-base ;
	jnz .L1      ; systems                          ;
	cmp eax, 0   ; is negative?                     ;
	jnl .L1      ; jump if positive or zero         ;
	mov byte [ebp], '-' ; put minus sign            ;
	inc ebp      ; click next                       ;
	neg eax      ; be positive                      ;
.L1:	mov edx, 0   ; clear                            ;
	div edi      ; R:=edx Q:=eax                    ;
	push edx     ; save R to stack                  ;
	inc ecx      ; update digit counter             ;
	cmp eax, 0   ; is Q zero?                       ;
	jne .L1      ; follow me                        ;
.L2:	pop edx      ; get a digit from the stack       ;
	mov al, [hexDigit + edx] ;                           ;
	mov byte [ebp], al  ; save to buffer            ;
	inc ebp      ; click next                       ;
	loop .L2     ; follow me                        ;
	mov edx, ebp ; pass buffer pointer to edx       ;
	sub edx, esi ; get number of bytes              ;
	pop eax      ;                                  ;
	pop ebp      ;                                  ;
	pop ecx      ; re-establish registers           ;
	ret          ; bye itoa                         ;
;--------------------;----------------------------------;
; idisplay: displays an integer number to stdout        ;
;-------------------------------------------------------;
; input: eax - an integer number                        ;
;        edi - radix                                    ;
;-------------------------------------------------------;
; calls: itoa, sndisplay                                ;
;----------------------;--------------------------------;
idisplay:              ;                                ;
	push esi       ; backup registers               ;
	push ecx       ;                                ;
	push edx       ; itoa                           ;
	sub esp, 32    ; allocate output buffer         ;
	mov esi, esp   ; pass it to esi                 ;
	call itoa      ; convert and                    ;
	mov ecx, esi   ; input for sndisplay            ;
	call sndisplay ; display                        ;
	add esp, 32    ; balance the stack              ;
	pop edx        ;                                ;
	pop ecx        ;                                ;
	pop esi        ; re-establish registers         ;
	ret            ; bye idisplay                   ;
;----------------------;--------------------------------;
; hexdump: dumps an integer in hex to stdout            ;
;-------------------------------------------------------;
; calls: idisplay, cdisplay                             ;
;---------------------;---------------------------------;
%macro hexdump 1      ;                                 ;
	push eax      ; backup registers                ;
	push edi      ;                                 ;
	mov eax, %1   ; pass the integer to eax         ;
	mov edi, 16   ; radix                           ;
	call idisplay ; ze dump                         ;
	cdisplay 10   ; new line                        ;
	pop edi       ;                                 ;
	pop eax       ; re-establish registers          ;
%endmacro             ;                                 ;
;---------------------;---------------------------------;-------;
; get_program_break                                             ;
;---------------------------------------------------------------;
; output: eax                                                   ;
;---------------------------------------------------------------;
; outputs the current location of the program break in eax      ;
;--------------------;------------------------------------------;
get_program_break:   ;
	nop          ; gdb
	push ebx     ; backup 1
	mov eax, 45  ; sys_brk
	sub ebx, ebx ; clear
	int 0x80     ; :)
	pop ebx      ; re-establish 1
	ret          ; bye get_program_break
;--------------------;------------------------------------------;
; allocate_memory                                               ;
;---------------------------------------------------------------;
; input: esi - size of each member(4 bytes, 8 bytes etc.)       ;
;        ecx - no. of members                                   ;
;---------------------------------------------------------------;
; output: ebx - start address of newly allocated block          ;
;         eax - the new location of program break(PB)           ;
;---------------------------------------------------------------;
; allocate memory from the heap using brk                       ;
;--------------------;------------------------------------------;
allocate_memory:     ;
	nop          ; gdb
	push edx     ; backup 1
	call get_program_break ; -> eax
	mov ebx, eax ; pass PB to ebx
	mov eax, ecx ; pass ecx to eax for multiplication
	mul esi      ; now eax holds the memory block size 
	push ebx     ; backup 2
	add ebx, eax ; calculate the new PB
	mov eax, 45  ; sys_brk 
	int 0x80     ; yeah!
	pop ebx      ; re-establish 2
	pop edx      ; re-establish 1
	ret          ; bye allocate_memory
;--------------------;------------------------------------------;
; rnd                                                           ;
;---------------------------------------------------------------;
; linear congruential method (glibs)                            ;
;---------------------------------------------------------------;
; output: eax - the generated random number [0, MAXRND]        ;
;---------------------------------------------------------------;
; modifies: nextRnd                                                ;
;-----------------------------;---------------------------------;
rnd:    nop                   ; gdb
	push ebx              ; backup
	push edx              ;
	mov eax, dword [nextRnd] ; prepare for multiplication 
	mov ebx, 1103515245   ; the multiplier
	mul ebx               ; edx:eax <- eax*ebx
	add eax, 12345        ; the increment 
	and eax, MAXRND      ; bits [0..30]
	mov dword [nextRnd], eax ; update next value
	pop edx               ; re-establish
	pop ebx               ;
	ret                   ; bye rnd
;-----------------------------;---------------------------------;
; srnd                                                          ;
;---------------------------------------------------------------;
; initializes nextRnd                                           ;
;---------------------------------------------------------------;
; input: eax - the seed if negative than use sys_time           ;
;---------------------------------------------------------------;
; output: none                                                  ;
;---------------------------------------------------------------;
; modifies: nextRnd                                             ;
;-------------------------------;-------------------------------;
srnd:   nop                     ; gdb
	push ebx                ; backup
	cmp eax, 0              ; is positive or zero?
	jge .L                  ; follow me
	mov eax, 13             ; sys_time
	mov ebx, 0              ; NULL
	int 0x80                ; syscall
.L:	mov dword[nextRnd], eax ; initialize nextRnd
	pop ebx                 ; re-establish
	ret                     ; bye srnd
;-------------------------------;-----------------------
; initcmb: initialize combinations
;-------------------------------------------------------
; in:  ebx - combinations array address (c)
;       dl - k
;       dh - n
;-------------------------------------------------------
; out: void
;-------------------------------------------------------
; modify: [ebx]
;-------------------------------------------------------
; notes: Knuth Vol4A Algorithm L pg. 358
;-------------------------------;-----------------------
initcmb:                           ;
	nop                     ; gdb
	push ecx                ; index (j)
	;;                      ;
	sub ecx, ecx            ; j <- 0
.Nyu:	cmp cl, dl              ; j < k?
	jz  .De                 ; exit
	mov byte[ebx+ecx], cl   ; c[j] <- j
	inc ecx                 ; j++
	jmp .Nyu                ; re-enter
.De:	mov byte[ebx+ecx], dh   ; c[k] <- n
	mov byte[ebx+ecx+1], 0  ; c[k+1] <- 0
	;;                      ;
	pop  ecx                ; re-establish
	ret                     ; bye initcmb
;-------------------------------;-----------------------
; nextcmb: next combination
;-------------------------------------------------------
; in:  ebx - combinations array address (c)
;       dl - k
;-------------------------------------------------------
; out: eax - zero if nothing more to generate
;-------------------------------------------------------
; modify: [ebx]
;-------------------------------------------------------
; notes: Knuth Vol4A Algorithm L pg. 358
;-------------------------------;-----------------------
nextcmb:                           ;
	nop                     ; gdb
	push ecx                ; index (j)
	;;                      ;
	sub  ecx, ecx           ; j <- 0
	sub  eax, eax           ; clear
	mov  al, [ebx]          ; al <- c[0]
.Nyu:	inc  al                 ; al <- c[j] + 1
	cmp  al, [ebx+ecx+1]    ; al = c[j+1]?
	jnz  .De                ; exit
	mov  byte[ebx+ecx], cl  ; c[j] <- j
	inc  ecx                ; j++
	jmp  .Nyu               ; re-enter
.De:    sub  eax, eax           ; set output to 0
	cmp  cl, dl             ; j = k?
	jz   .Q                 ; go go go
	inc  byte[ebx+ecx]      ; c[j]++
	mov  eax, 1             ; eax <- 1
.Q:                             ;
	pop  ecx                ; re-establish
	ret                     ; bye nextcmb
;-------0-------1-------2-------;-------4-------5-------6-------
; atoi: ascii to int
;---------------------------------------------------------------
; in: esi - string address (s)
;     edi - radix
;---------------------------------------------------------------
; out: eax - ze integer
;---------------------------------------------------------------
; modify: no
;---------------------------------------------------------------
; notes: the string has to have a terminal zero byte
;-------0-------1-------2-------3-------;-------5-------6-------
atoi:                           	;
	nop                     	; gdb
	push 	edx                	; backup
	push	ecx			;
	push	ebx			;
	push	ebp			;
	push	esi			;
	;
	mov	ebx, 1			; powers of radix
	cmp	edi, 10			; ck for minus '-' sign
	jnz	.A			; nope
	cmp	byte[esi], '-'		; q u e s t i o n ?
	jnz 	.A			; nah
	mov	ebx, -1			; ha ha
	inc	esi			; what is this!?
	;
.A:	call	strlen			; get N_Digits
	mov	ecx, edx		; prepare for loop (j+1)
	xor	ebp, ebp		; clear
		;
.B:	movzx	edx, byte[esi+ecx-1]	; s[j]
	;
	cmp	edx, 'a'		; hex lowercase
	jb	.C			; nix
	sub	edx, 'W'		; get ze number
	jmp	.E			; continuer à répéter
				;
.C:	cmp	edx, 'A'		; hex uppercase
	jb	.D			; nixey
	sub	edx, '7'		; get ze number
	jmp	.E			; continuer à répéter
		;
.D:	sub	edx, '0'		; get ze digit
	jz	.F			; click next
.E:	mov	eax, edx		; prepare for mul
	mul	ebx			; edx:eax <- result
	add	ebp, eax		; assuming edx izzzero
;
.F:	mov	eax, ebx		; next pozition
	mul	edi			; wow!
	mov	ebx, eax		; no overflow ck
	loop	.B			; continuer à répéter
	;
	mov	eax, ebp		; eax <- ze N
			;		   **
	pop	esi			;
	pop	ebp			;
	pop	ebx			;
	pop	ecx			;
	pop  	edx                	; re-establish
	ret                     	; bye atoi
;-------0-------1-------2-------3-------;-------5-------6-------
; getrnd: generates a random number in the range [min, max]
;---------------------------------------------------------------
; in: ebx - min                                              
;     ecx - max                                              
;---------------------------------------------------------------
; out: edx                                                   
;---------------------------------------------------------------
; modify: none
;---------------------------------------------------------------
; notes: min + rnd() % (max - min + 1)
;-------0-------1-------2-------;-------4-------5-------6-------
getrnd: nop			;          
	push 	eax		; backup registers
	push	ecx     	; ._.
	call 	rnd     	; generates a random number (eax)
	sub 	ecx, ebx 	; max - min
	inc 	ecx      	; max - min + 1
	xor 	edx, edx 	; clear
	div 	ecx      	; edx now holds the reminder
	add 	edx, ebx 	; voilà
	pop 	ecx      	; re-establish registers
	pop 	eax      	; o_o
	ret          		; bye :)
