; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

.op "PUSH","N","9$1 73 8$1 73"
.op "POP","N","60 72 A$1 F0 B$1"
.op "CALL","W","D4 H1 L1"
.op "RTN","","D5"
.op "MOV","NR","9$2 B$1 8$2 A$1"
.op "MOV","NW","F8 H2 B$1 F8 L2 A$1"

include    bios.inc
include    kernel.inc


           org     2000h
begin:     br      start
           eever
           db      'Written by Michael H. Riley',0

start:
           lda     ra                  ; move past any spaces
           smi     ' '
           lbz     start
           dec     ra                  ; move back to non-space character
           ghi     ra                  ; copy argument address to rf
           phi     rf
           glo     ra
           plo     rf
loop1:     lda     rf                  ; look for first less <= space
           smi     33
           lbdf    loop1
           dec     rf                  ; backup to char
           ldi     0                   ; need proper termination
           str     rf
           ghi     ra                  ; back to beginning of name
           phi     rf
           glo     ra
           plo     rf
           ldn     rf                  ; get byte from argument
           lbnz    good                ; jump if filename given
           sep     scall               ; otherwise display usage message
           dw      o_inmsg
           db      'Usage: hexdump filename',10,13,0
           ldi     0ah
           sep     sret                ; and return to os
good:      ldi     high fildes         ; get file descriptor
           phi     rd
           ldi     low fildes
           plo     rd
           ldi     0                   ; flags for open
           plo     r7
           sep     scall               ; attempt to open file
           dw      o_open
           lbnf    opened              ; jump if file was opened
           ldi     high errmsg         ; get error message
           phi     rf
           ldi     low errmsg
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           ldi     04
           sep     sret                ; and return to os
opened:    ghi     rd                  ; make copy of descriptor
           phi     rb
           glo     rd
           plo     rb
           ldi     high buffer         ; buffer to rettrieve data
           phi     rf
           ldi     low buffer
           plo     rf

           ldi     0
           phi     r7
           plo     r7

mainlp:    mov     rc,16               ; want to read 16 bytes
           mov     rf,buffer           ; buffer to retrieve data
           ghi     rb                  ; get descriptor
           phi     rd
           glo     rb
           plo     rd
           sep     scall               ; read the header
           dw      o_read
           glo     rc                  ; check for zero bytes read
           lbz     done                ; jump if so
           glo     rc                  ; keep a copy of the count
           phi     rc
           ldi     high cbuffer        ; get character buffer
           phi     rf
           ldi     low cbuffer
           plo     rf
           sep     scall               ; start with current address
           dw      addchar
           db      ':'
           ghi     r7                  ; transfer address
           phi     rd
           glo     r7
           plo     rd
           sep     scall               ; add to buffer
           dw      f_hexout4
           sep     scall               ; then a space
           dw      addchar
           db      ' '
           mov     r8,buffer           ; buffer to retrieve data
linelp:    lda     r8                  ; get next byte
           plo     rd                  ; place for output
           sep     scall               ; print hex value
           dw      f_hexout2
           sep     scall               ; then a space
           dw      addchar
           db      ' '
           inc     r7                  ; increment address
           dec     rc                  ; decrement read count
           glo     rc                  ; see if done
           lbnz    linelp              ; loop back if not
           sep     scall               ; add an extra space
           dw      addchar
           db      ' '
           mov     r8,buffer           ; point back to character buffer
           ghi     rc                  ; get count
           sdi     16                  ; subtract from 16
           lbz     adv1                ; jump if 16 bytes were read
           plo     rc                  ; count
advlp2:    ldi     ' '                 ; add 3 spaces
           str     rf
           inc     rf
           str     rf
           inc     rf
           str     rf
           inc     rf
           dec     rc                  ; decrement count
           glo     rc                  ; get count
           lbnz    advlp2              ; loop until done
adv1:      ghi     rc                  ; copy count back to low byte
           plo     rc
advlp:     ldn     r8
           smi     33                  ; check for <= space
           lbnf    advdot              ; display a dot if so
           ldn     r8
           smi     127                 ; check for printable range
           lbdf    advdot              ; jump if outside
           ldn     r8                  ; recover character
           str     rf                  ; and add to output
           inc     rf
           lbr     advgo
advdot:    sep     scall               ; use dot for undisplayable
           dw      addchar
           db      '.'
advgo:     inc     r8                  ; move to next character
           dec     rc                  ; decrement count
           glo     rc                  ; see if done
           lbnz    advlp               ; loop back if not
           sep     scall               ; display the line
           dw      display
           lbr     mainlp              ; and loop back til done

done:      sep     scall               ; close the file
           dw      o_close
           ldi     high cbuffer        ; get character buffer
           phi     rf
           ldi     low cbuffer
           plo     rf
           sep     scall               ; end marker
           dw      addchar
           db      '*'
           sep     scall               ; display the line
           dw      display
           ldi     0
           sep     sret                ; return to os



display:   sep     scall               ; add a space
           dw      addchar
           db      13
           sep     scall               ; add a space
           dw      addchar
           db      10
           sep     scall               ; add a space
           dw      addchar
           db      0
           ldi     high cbuffer        ; get character buffer
           phi     rf
           ldi     low cbuffer
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           sep     sret

addchar:   lda     r6                  ; retrieve inline character
           str     rf                  ; store into buffer
           inc     rf
           sep     sret                ; and return to caller
           

errmsg:    db      'File not found',10,13,0
fildes:    db      0,0,0,0
           dw      dta
           db      0,0
           db      0
           db      0,0,0,0
           dw      0,0
           db      0,0,0,0

endrom:    equ     $

.suppress

buffer:    ds      20
cbuffer:   ds      80
dta:       ds      512

           end     begin

