draw_line:
	; a0 - screen adddress
	; a6 - custom base
	; d0/d1 - pos 0
	; d2/d3 - pos 1
	; XCLIP and YCLIP should contain rightmost and bottommost pixel position

	; used but preserved:a0,a6
	; free: a3,a4,a5,a7

	; Helper macro to order points s.t. \1 <= \2.
order	macro 
	cmp.w	\1,\3
	bgt	.l\1\2\3\4
	exg	\1,\3 
	exg	\2,\4
.l\1\2\3\4:
	endm

	; Helper macro to find intersection point \5
isec	macro
	move	\5,d5
	sub	\1,d5
	move	\4,d6
	sub	\2,d6
	muls.w	d5,d6
	move	\3,d5
	sub	\1,d5
	divs.w	d5,d6
	add.w	d6,\2
	move.w	\5,\1
	endm


	; Clip against x min and xmax
	order	d0,d1,d2,d3	; order points left-right
	cmp.w	#0,d2
	ble	.done		; xmax < XCLIP0 -> done
	cmp.w	#XCLIP,d0	
	bge	.done		; XCLIP1 < xmin -> done
	cmp.w	#0,d0		; XCLIP0 <= xmin 
	bge	.noxc0
	isec	d0,d1,d2,d3,#0	; clip against left side

.noxc0:
	cmp.w	#XCLIP,d2	; xmax < XCLIP1 -> no clipping with XCLIP1
	ble	.noxc1
	isec	d2,d3,d0,d1,#XCLIP	; clip against right side
.noxc1:

	; Clip against y min and y max
	order	d1,d0,d3,d2	; order top to bottom
	cmp.w	#0,d3
	ble	.done		; ymax < YCLIP0
	cmp.w	#YCLIP,d1
	bge	.done		; YCLIP1 < ymin

	cmp.w	#0,d1
	bge	.noyc0
	isec	d1,d0,d3,d2,#0
.noyc0:
	cmp.w	#YCLIP,d3
	ble	.noyxc1
	isec	d3,d2,d1,d0,#YCLIP
.noyxc1:

	cmp.w	d1,d3		; 4(1/0) Always draw line from top down
	bgt.b	.dwnw		; (halves number of octants and fixes
	beq	.done		; skip horizontal lines when filling
	exg	d0,d2 
	exg	d1,d3
.dwnw:

	sub.w	d1,d3
	moveq.l	#0,d5
	sub.w	d0,d2
	bpl.b	.dxpos
	neg.w	d2
	addq.w	#2,d5
.dxpos:

	cmp.w	d3,d2		; make sure d2 is greater than d3
	bge.b	.dxge		; add bit1 if |dy| > |dx|
	exg	d2,d3
	addq.l	#4,d5		; |dx| < |dy| -> set bit 2 of d5
.dxge:

	; d0: BLTCON0 & BLTCON1 - step 1: shift value and word index
	ext.l	d0		; clear upper word (assumes x0 is positive)
	ror.l	#4,d0		; 8+2*4=16(1/0) lsb in upper part of upper word

	; a2: BLTCPT & BLTDPT - word of first pixel of the line
	mulu	#40,d1		; d1 = 40*y0  less than 1600 lines -> 16 bits
	add.w	d0,d1		; word offset
	add.w	d0,d1		; word offset x 2
	lea	(a0,d1.w),a2    ; a2 = a0 + 40*d1 + 2*d0 -> word addr of line start

	; d6: BLTSIZE
	move.w	d2,d6		; d6 = dx
	addq.w	#1,d6		; d6 = dx+1
	lsl.w	#6,d6
	beq	.done
	addq.w	#2,d6		; d6 = BLTSIZE value

	; d4: BLTCMOD & BLTBMOD - hi: width in bytes, lo: 4*dy
	move.w  #40,d4
	swap    d4
	asl.w   #2,d3		; d3 = 4*dy
	move.w  d3,d4		; d4-hi: width in bytes, d4-lo: 4*dy

	; d3 BTLAMOD & BLTDMOD - hi: 4(dy-dx), lo: 4dy
	add.w	d2,d2		; d2 = 2*dx
	sub.w	d2,d3		; d3 = 4dy - 2dx
	bpl	.nsgn
	addq.w	#8,d5		; 4dy-2dx < 0 -> set bit 3 of d5
.nsgn:
	; a1 BLTAPT - 4dy-2dx
	movea.w	d3,a1		; sign-extend 4dy-2dx into a1

	; d3: BLTAMOD & BLTDMOD - hi: 4*dy - 4*dx, lo: width in bytes
	sub.w	d2,d3		; d3 = 4dy - 4dx
	swap	d3
	move	#40,d3		; store width in low

	; d0: BLTCON0 & BLTCON1 - step 2: set bits and octant

	; a b C + A B c + A b c = %01001010 = 4A

	or.l	#$B4A0000,d0	; set BLTCON0 flag bits
;	or.l	#$BFA0000,d0	; set BLTCON0 flag bits
	move.w	oct(pc,d5),d0	; set BLTCON1 octant and flag bits

	move.w	d7,d1
.plane:	btst	#0,d1
	beq.b	.zero

	move.w	#$300,$180(a6)
.wait:	btst	#14,DMACONR(a6)
	bne.b	.wait
	move.w	#$030,$180(a6)

	move.l	d3,BLTAMOD(a6)	; set BLTAMOD ($064) and BLTDMOD ($066)
	move.l	a1,BLTAPTH(a6)
	move.l	a2,BLTCPTH(a6)
	move.l	a2,BLTDPTH(a6)
	move.l	d0,BLTCON0(a6)	; set BLTCON0 ($040) and BLTCON1 ($042)
	move.l	d4,BLTCMOD(a6)	; set BLTCMOD ($060) and BLTBMOD ($062)

	move.w	#$8000,BLTADAT(a6)
	moveq.l	#-1,d2
	move.w	d2,BLTBDAT(a6)	; line pattern
	move.l	d2,BLTAFWM(a6)	; $ffff in BLTAFWM and BLTALWM

	move.w	d6,BLTSIZE(a6)

.zero:	lsr.w	#1,d1
	tst.w	d1
	beq.b	.done

	add.l	#40*150,a2

	bra.b	.plane


.done	rts
oct:	dc.w	(4<<2)|%00000011	; 4dy-2dx >= 0 :: |dx| >= |dy| :: dx pos => oct 4(7)
	dc.w	(5<<2)|%00000011 	; 4dy-2dx >= 0 :: |dx| >= |dy| :: dx neg => oct 5(4)
	dc.w	(0<<2)|%00000011	; 4dy-2dx >= 0 :: |dx| <  |dy| :: dx pos => oct 0(6)
	dc.w	(2<<2)|%00000011	; 4dy-2dx >= 0 :: |dx| <  |dy| :: dx neg => oct 2(5)
	dc.w	(4<<2)|%01000011	; 4dy-2dx <  0 :: |dx| >= |dy| :: dx pos => oct 4(7)
	dc.w	(5<<2)|%01000011	; 4dy-2dx <  0 :: |dx| >= |dy| :: dx neg => oct 5(4)
	dc.w	(0<<2)|%01000011	; 4dy-2dx <  0 :: |dx| <  |dy| :: dx pos => oct 0(6)
	dc.w	(2<<2)|%01000011	; 4dy-2dx <  0 :: |dx| <  |dy| :: dx neg => oct 2(5)
