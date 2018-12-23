	; a0 - pointer to copperlist bitplane pointers
scroller_init:
	lea	scrollbitp,a0
	move.l	#scrollscreen+2,d0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	rts

scroller_main:

	subq.b	#1,scrollcnt			; should we push new char?
	bne.b	.shift
	move.b	#7,scrollcnt

	move.l	scrollp,a0			; find character to print
	move.b	(a0),d0
	tst.b	d0
	bne.b	.ntend
	move.l	#scrolltext-1,scrollp
.ntend:	addq.l	#1,scrollp

	lea	chars6x5(pc),a0			; search for char to find offset
	move.w	#0,d1
.find:	cmp.b	(a0,d1.w),d0
	beq.b	.write
	tst.b	(a0,d1.w)
	beq.b	.write
	addq.w	#1,d1
	bra	.find

.write	lea	font6x5(pc),a0			; write new char
	mulu	#5,d1
	add.l	d1,a0
	lea	scrollscreen+40,a2
	move.b	(a0)+,0(a2)
	move.b	(a0)+,42(a2)
	move.b	(a0)+,84(a2)
	move.b	(a0)+,126(a2)
	move.b	(a0)+,168(a2)

.shift:	lea	CUSTOM,a1			; shift scroller 1 pixel to the left

	move	#1000,d0
	btst	#14,DMACONR(a1)			; wait for blitter ready
.wait:	btst	#14,DMACONR(a1)
	bne.b	.wait

	move.l	#$ffffffff,BLTAFWM(a1)		; no mask
	move.l	#$00000000,BLTAMOD(a1)
	move.l	#$00000000,BLTDMOD(a1)
	move.l	#$f9f00000,BLTCON0(a1)		; A shift, USEA&D, LF4..7
	move.l	#scrollscreen+2,BLTAPTH(a1)	; source address
	move.l	#scrollscreen,BLTDPTH(a1)	; destination address

	move	#(5*64)+21,BLTSIZE(a1)
	rts

scrollp:	dc.l	scrolltext
scrollcnt:	dc.b	1
scrolltext:	dc.b	'yo man, this is a small 6x5 scroller! ',0
chars6x5:	dc.b	"abcdefghijklmnopqrstuvwxyz !.,-0123456789'",0
font6x5:	include "inc_font6x5.S"
