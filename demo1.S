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

	move.l	mainscreenp,d0			; Flip and update copperlist
	move.l	mainscreenp+4,d1
	move.l	d1,mainscreenp
	move.l	d0,mainscreenp+4
	lea	mainbitp,a0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	rts

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

mainscreen1:	blk.b	40*150,$f0
mainscreen2:	blk.b	40*150,$0f
