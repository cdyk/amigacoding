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
BLTCPTH equ	$048
BLTDPTH	equ	$054
BLTSIZE	equ	$058
BLTCON0	equ	$040
BLTCON1 equ	$042

BLTCMOD equ	$060
BLTBMOD equ	$062
BLTAMOD equ	$064
BLTDMOD equ	$066

BLTBDAT equ	$072
BLTADAT	equ 	$074


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

	bsr	main_init
	bsr	scroller_init

	move.l	#copperlist,COP1LCH(a1)
	move.w	#%1000001111000000,DMACON(a1)	; enable bitplane + copper + blitter dma

loop:
	move.l	VPOSR(a1),d0			; wait for line $40
	and.l	#$0001ff00,d0
	cmp.l	#$00004000,d0
	bne.b	loop

	move.w	#$f00,$dff180			; bg red on mainloop start

	bsr	scroller_frame
	bsr	main_frame

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

main_init:
	move.l	mainscreenp,d0
	lea	mainbitp,a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	rts

main_frame:

	move.l	#50,d0
	move.l	#50,d1
	move.l	#100,d2
	move.l	#100,d3
	bsr	draw_line

	move.l	mainscreenp,d0			; Flip and update copperlist
	move.l	mainscreenp+4,d1
	move.l	d1,mainscreenp
	move.l	d0,mainscreenp+4
	lea	mainbitp,a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	rts


draw_line:
	lea	CUSTOM,a6

	cmp.w	d1,d3				; Always draw line from top down
	bgt.b	.noswap				; (halves number of octants and fixes
	beq	.done				;  endpoint-consistency when filling)
	exg	d0,d2
	exg	d1,d3
.noswap:
	sub.w	d1,d3				; d3 contains |dy|

	moveq.l	#0,d5				; assume octant 0 or 4 for now
	sub.w	d0,d2				; d2 contains dx
	bpl.b	.oct04
	neg.w	d2				; d2 contains |dx|
	moveq.l	#1,d5				; octant is 2 or 5.

.oct04:	cmp	d2,d3
	bge.b	.oct45
	exg	d2,d3
	or.w	#$2,d5				; octant is 0 or 2
.oct45:

.wait:	btst	#14,DMACONR(a6)			; wait for blitter ready
	bne.b	.wait

	move.w	#$8000,BLTADAT(a6)
	moveq.l	#$1,d6
	move.w	#$ffff,BLTBDAT(a6)		; line pattern
	move.l	d6,BLTAFWM(a6)			; $ffff in BLTAFWM and BLTALWM

	move	d3,d6				; BLTAMOD = 4*(dy-dx)
	sub	d2,d6
	lsl.w	#2,d6
	move.w	d6,BLTAMOD(a6)

	move	d3,d6				; BLTBMOD = 4*dy
	lsl.w	#2,d6
	move.w	d6,BLTBMOD(a6)

	move.w	#40,BLTCMOD(a6)			; BLTCMOD = byte width
	move.w	#40,BLTDMOD(a6)			; BLTDMOD = byte width

	move.w 	d3,d6				; BLTAPT = 4*dy - 2*dx
	lsl.w	#2,d6
	sub.w	d2,d6
	sub.w	d2,d6
	bpl.b 	.pos
	or.w	#4,d5				; if 4dy-2dx<1, signflag=1
.pos
	ext.l	d6
	move.l	d6,BLTAPTH(a6)

	move.w	d1,d6				; BLTCPT = BLTDPT = first word of line
	mulu	#40,d6
	move.w	d0,d7
	lsr.w	#4,d7
	add.w	d7,d7
	add.w	d7,d6
	move.l	mainscreenp,a0
	ext.l	d6
	add.l	d6,a0
	move.l	a0,BLTCPTH(a6)
	move.l	a0,BLTDPTH(a6)

	move	d0,d6
	ror.w	#4,d6
	or.w 	#$BFA,d6
	move.w	d6,BLTCON0(a6)
	move.w	oct(pc,d5),BLTCON1(a6)

	addq.w	#1,d3				; BLTSIZE = dx+1 in bits 15..6, 2 in bits 5-0
	lsl	#6,d3
	addq.w 	#2,d3
	move.w  d3,BLTSIZE(a6)

	move.w	#$0f0,$180(a6)
.done:
	rts
oct:	dc.w	4*2+00,5*2+00,0*2+00,2*2+00
	dc.w	4*2+64,5*2+64,0*2+64,2*2+64

	include "inc_miniscroller.S"

mainscreenp:	dc.l	mainscreen1, mainscreen2

		section ChipRAM,Data_c

copperlist:	dc.l	$01800000
		dc.l	$00920038,$009400d0		; DDFSTRT and DDFSTOP

		dc.l	$01080004,$010a0000		; BPL1MOD BPL2MOD
scrollbitp:	dc.l	$00e00000,$00e20000
		dc.l	$3021fffe			; wait line $30
		dc.l	$01800002,$01001200		; BPU0 on

		dc.l	$3521fffe			; line $35
		dc.l	$0180000f,$0180000c,$01000200	; BPU0 off
		dc.l	$3621fffe
		dc.l	$0180008f,$01080000,$010a0000		; BPL1MOD BPL2MOD
mainbitp:	dc.l	$00e00000,$00e20000
		dc.l	$3721fffe,$01800002,$01001200	; BPU0 on
		dc.l	$01800000

		dc.l	$cd21fffe,$01000200
		dc.l	$01800004

		dc.l	$ffe1fffe

		dc.l	$1721fffe,$0180008f
		dc.l	$1821fffe,$0180000f
		dc.l	$1921fffe,$01800000

		dc.l	$fffffffe

scrollscreen:	blk.b	44*5+2,0

mainscreen1:	blk.b	40*150,$00
mainscreen2:	blk.b	40*150,$00
