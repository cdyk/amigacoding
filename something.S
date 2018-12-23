CUSTOM	equ	$dff000

DMACON  equ	$096
DMACONR	equ	$002

INTENA 	equ	$09a
INTENAR	equ	$01c

INTREQ	equ	$09c
INTREQR	equ	$01e

ADKCON	equ	$09e
ADKCONR	equ	$010

COP1LCH	equ	$080
COPJMP1	equ	$088
VPOSR	equ	$004

BLTAFWM	equ	$044
BLTAPTH	equ	$050
BLTDPTH	equ	$054
BLTSIZE	equ	$058
BLTCON0	equ	$040
BLTAMOD equ	$064
BLTDMOD equ	$066


start:
	move.l	$80.w,-(a7)
	move.l	#program,$80.w
	trap	#0
	move.l	(a7)+,$80.w
	rts

program:
	lea	CUSTOM,a1
	move.w	DMACONR(a1),-(a7)		; save enabled dma channels
	move.w	#%0111111111111111,DMACON(a1)	; turn off all dma 
	move.w	INTENAR(a1),-(a7)		; save enabled interrupts
	;move.w	#%0111111111111111,INTENA(a7)	; disable all interupts
	move.w	INTREQR(a1),-(a7)		; store current interrupt request bits
	move.w	ADKCONR(a1),-(a7)		; store current disk and sound control

	bsr	scroller_init

	move.l	#copperlist,COP1LCH(a1)
	move.w	#%1000001111000000,DMACON(a1)	; enable bitplane + copper + blitter dma

loop:
	move.l	VPOSR(a1),d0			; wait for line $40
	and.l	#$0001ff00,d0
	cmp.l	#$00004000,d0
	bne.b	loop

	move.w	#$f00,$dff180			; bg red on mainloop start

	bsr	scroller_main

	move.w	#$000,$dff180			; bg black on mainloop finish

	btst	#6,$bfe001
	bne.b	loop

	lea	CUSTOM,a1

	move.l	$4,a6
	move.l	156(a6),a6
	move.l	38(a6),COP1LCH(a1)		; restore system copper list

	move.w	#$8000,d1			; enable bit

	move.w	(a7)+,d0			; restore disk and sound control
	or.w	d1,d0
	move.w	d0,ADKCON(a1)

	move.w	(a7)+,d0			; restore interrupt request bits
	or.w	d1,d0
	move.w	d0,INTREQ(a1)

	move.w	(a7)+,d0			; restore enabled interrupts
	or.w	d1,d0
	move.w	d0,INTENA(a1)

	move.w	(a7)+,d0			; restore enabled dma channels
	or.w	d1,d0
	move.w	d0,DMACON(a1)

	rte

scroller_init:
	lea	scrollbitp,a0			; set bitplane pointers in copper list
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
font6x5:	include "font6x5.S"

		section ChipRAM,Data_c

copperlist:	dc.l	$01800000
		dc.l	$01080002,$010a0000
scrollbitp:	dc.l	$00e00000,$00e20000
		dc.l	$ffe1fffe
		dc.l	$1021fffe,$01800002,$01001200	; BPU0 on
		dc.l	$1121fffe,$01800004
		dc.l	$1221fffe,$01800006
		dc.l	$1321fffe,$01800008
		dc.l	$1421fffe,$0180000a
		dc.l	$1521fffe,$0180000c,$01000200	; BPU0 off
		dc.l	$1621fffe,$0180000e
		dc.l	$1721fffe,$0180000f
		dc.l	$1821fffe,$0180000e
		dc.l	$1921fffe,$0180000c
		dc.l	$1a21fffe,$0180000a
		dc.l	$1b21fffe,$01800008
		dc.l	$1c21fffe,$01800006
		dc.l	$1d21fffe,$01800004
		dc.l	$1e21fffe,$01800002
		dc.l	$1f21fffe,$01800000
		dc.l	$fffffffe

scrollscreen:	blk.b	42*5+2,0
