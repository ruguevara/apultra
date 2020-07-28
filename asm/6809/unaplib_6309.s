;  unaplib-6309.s - aPLib decompressor for H6309 - 145 bytes
;
;  in:  x = start of compressed data
;       y = start of decompression buffer
;  out: y = end of decompression buffer + 1
;
;  Copyright (C) 2020 Emmanuel Marty
;
;  This software is provided 'as-is', without any express or implied
;  warranty.  In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.


; Original M6809 version written by Emmanuel Marty with Hitachi 6309 enhancements
; added by Doug Masten.
;
; Main advantage of H6309 CPU is the "TFM" instruction which can copy one
; byte of memory in 3 clock cycles vs a traditional copy loop that takes
; 20 clock cycles.

; Options:
;   APLIB_VAR
;     Define variable to point to a DP memory location for a memory space
;     and speed optimization.
;     ex. APLIB_VAR equ <memory location>
;
;   APLIB_LONG_OFFSET_DISABLE
;     Defined variable to disable long offsets >= 32000 for a speed and space
;     optimization. Only enable this if you know what you are doing.
;     ex. APLIB_LONG_OFFSET_DISABLE equ 1


; define options
         ifdef APLIB_VAR
apbitbuf equ APLIB_VAR     ; bit queue (use DP memory for mem & space optimization)
         else
apbitbuf fcb 0             ; bit queue (DEFAULT - use extended memory)
         endc


apl_decompress
         lda #$80          ; initialize empty bit queue
         sta apbitbuf      ; plus bit to roll into carry
         tfr x,u

apcplit  ldb ,u+           ; copy literal byte
apwtlit  stb ,y+

         lda #3            ; set 'follows literal' flag
apwtflg  sta aplwm+2

aptoken  bsr apgetbit      ; read 'literal or match' bit
         bcc apcplit       ; if 0: literal

         bsr apgetbit      ; read '8+n bits or other type' bit
         bcs apother       ; if 11x: other type of match

         bsr apgamma2      ; 10: read gamma2-coded high offset bits
aplwm    subd #$0000       ; high offset bits == 2 when follows_literal == 3 ?
         bcc apnorep       ; if not, not a rep-match

         bsr apgamma2      ; read repmatch length
         bra apgotlen      ; go copy large match

apnorep  tfr b,a           ; transfer high offset bits to A
         ldb ,u+           ; read low offset byte in B
         std aprepof+1     ; store match offset
         tfr d,x           ; transfer offset to X

         bsr apgamma2      ; read match length

         ifndef APLIB_LONG_OFFSET_DISABLE
         cmpx #$7D00       ; offset >= 32000 ?
         bge apincby2      ; if so, increase match len by 2
         endc
         cmpx #$0500       ; offset >= 1280 ?
         bge apincby1      ; if so, increase match len by 1
         cmpx #$80         ; offset < 128 ?
         bge apgotlen      ; if so, increase match len by 2
apincby2 incd
apincby1 incd
apgotlen tfr d,w           ; copy match length to W for "TFM" instruction
aprepof  ldd #$aaaa        ; load match offset
         negd              ; reverse sign of offset in D

         addr y,d          ; put backreference start address in D (dst + offset)
         tfm d+,y+         ; copy matched bytes

         lda #2            ; clear 'follows literal' flag
         bra apwtflg

apgamma2 ldd #1            ; init to 1 so it gets shifted to 2 below
apg2loop bsr apgetbit      ; read data bit
         rolb              ; shift into D
         rola
         bsr apgetbit      ; read continuation bit
         bcs apg2loop      ; loop until a zero continuation bit is read
apdone   rts

apdibits bsr apgetbit      ; read bit
         rolb              ; push into B
apgetbit lsl apbitbuf      ; shift bit queue, and high bit into carry
         bne apdone        ; queue not empty, bits remain
         pshs a            ; save reg A
         lda ,u+           ; read 8 new bits
         rola              ; shift bit queue, and high bit into carry
         sta apbitbuf      ; save bit queue
         puls a,pc         ; pop reg A and return

apshort  clrb
         bsr apdibits      ; read 2 offset bits
         rolb
         bsr apdibits      ; read 4 offset bits
         rolb
         beq apwtlit       ; if zero, go write it

         negb              ; reverse offset in D
         ldb b,y           ; load backreferenced byte from dst+offset
         bra apwtlit       ; go write it

apother  bsr apgetbit      ; read '7+1 match or short literal' bit
         bcs apshort       ; if 111: 4 bit offset for 1-byte copy

         clra              ; clear high bits in A
         ldb ,u+           ; read low bits of offset + length bit in B
         beq apdone        ; check for EOD
         lsrb              ; shift offset in place, shift length bit into carry
         std aprepof+1     ; store match offset
         ldb #1            ; len in B will be 2*1+carry:
         rolb              ; shift length, and carry into B
         bra apgotlen      ; go copy match