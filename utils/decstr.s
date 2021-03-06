; Get a byte parameter from BASIC text and convert it to string and print it.
; 
; Purpose: test byte to string conversion.

; *** labels ***

chrgot          = $79       ; read current BASIC text character again
strout          = $ab1e     ; print str in A/Y
chrout          = $ffd2     ; send a char in A (PETSCII) to the current output device
chkcom          = $aefd     ; check for and skip comma; SYNTAX ERROR if the next char is not a comma
getbyt          = $b79e     ; get a byte parameter from BASIC text into X
                            ; (TYPE MISMATCH if not a number, ILLEGAL QUANTITY if not in 0-255,
                            ; floating point numbers are truncated)

; *** main ***

                *=$0334         ; sys820
getbyte         jsr chrgot      ; what was the last character again?
                beq eolerror    ; if 0 then it is the end of the line -> parameter missing				
                jsr chkcom      ; check comma
                jsr getbyt      ; get a byte parameter (stored in X)
                txa             ; X -> A
                pha             ; push the parameter onto the stack
                jsr byt2str     ; convert the byte in A to string and print it
                lda #$0d        ; print a CR
                jsr chrout
                pla             ; get the parameter from stack
                ldx #<str       ; store the resulting null terminated string at this address
                ldy #>str
                jsr byt2stra    ; convert to a right aligned string with leading spaces
                jsr strout      ; the address is in A/Y upon return from byt2stra, print
end             rts             ; return

; Parameter missing error.	
eolerror        lda #<eolerrstr ; string addr low byte
                ldy #>eolerrstr ; string addr high byte
                jsr strout      ; print str in A/Y
                jmp end         ; jump to end

; *** subroutines ***

; name:         byt2str
; description:  convert a byte to string
; input:        a byte in A
; output:       - (prints the string directly)
; see also/thx: https://www.c64-wiki.de/wiki/Assembler_Beispiel_Division
byt2str
.block
                ldx #$00        ; X = 0
loop            jsr div10       ; perform A/10; quotient will be in Y, remainder in A
                pha             ; push the remainder on the stack
                inx             ; X++ (X counts the decimal places)
                tya             ; transfer quotient from Y to A
                bne loop        ; if A != 0 then jump to loop
loop2           pla             ; get the number at the highest decimal position
                ora #$30        ; convert it to PETSCII (https://en.wikipedia.org/wiki/PETSCII)
                jsr chrout      ; send char in A to the screen
                dex             ; X--
                bne loop2       ; while x != 0 jump to loop2
                rts
.bend

; name:         byt2stra
; description:  converts a byte to a right aligned 
;               null terminated string
;               destroys X and Y
; input:        a byte in A, storage address in X/Y (low/high)
; output:       address of a null terminated 4 byte string in A/Y (ready to print using strout)
; resources:    $fb and $fc from FREEZP
; see also/thx: https://www.c64-wiki.de/wiki/Assembler_Beispiel_Division
byt2stra
.block
                stx $fb         ; store the address of the resulting string on the zero page
                sty $fc
                pha             ; push the byte on the stack
                ldy #$00        ; fill the first two bytes with spaces
                lda #$20
                sta ($fb),y
                iny
                sta ($fb),y                
                ldy #$03        ; store $00 at the end of the string (str+3)
                lda #$00
                sta ($fb),y
                pla             ; get the byte to convert back from the stack
                ldx #$00        ; X = 0
loop            jsr div10       ; perform A/10; quotient will be in Y, remainder in A                
                pha             ; push the remainder on the stack
                inx             ; X++ (X counts the decimal places)
                tya             ; transfer quotient from Y to A
                bne loop        ; if A != 0 then jump to loop
                txa             ; X -> A
                eor #$03        ; calculate 3-X (position in the string where the first digit will be placed)
                tay             ; transfer the result into Y
loop2           pla             ; get the number at the highest decimal position
                ora #$30        ; convert it to PETSCII (https://en.wikipedia.org/wiki/PETSCII)
                sta ($fb),y     ; store it in the string
                iny             ; Y++
                dex             ; X--
                bne loop2       ; while x != 0 jump to loop2
                lda $fb         ; address of the string in A/Y
                ldy $fc
                rts
.bend

; name:         div10
; description:  divide a byte by 10
; input:        a byte in A
; output:       Y: quotient; A: remainder
; see also/thx: https://www.c64-wiki.de/wiki/Assembler_Beispiel_Division
div10
.block
                sec             ; set carry for subtraction
                ldy #$ff        ; Y = $ff
loop            iny             ; Y++
                sbc #$0a        ; A -= 10
                bcs loop        ; carry is high (A > 10)? jump to loop
                adc #$0a        ; carry low -> A += 10 (correct negative)
                rts
.bend


; *** data ***

eolerrstr		.byte $0d
                .null "?parameter missing  error"

str