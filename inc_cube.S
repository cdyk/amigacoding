vertex_N	equ	8

	even
vertices:
	dc.w	-100,100,100
	dc.w	100,100,100
	dc.w	100,-100,100
	dc.w	-100,-100,100
	dc.w	-100,100,-100
	dc.w	100,100,-100
	dc.w	100,-100,-100
	dc.w	-100,-100,-100

face_N	equ	6
faces:
	dc.w	4		; face 0
	dc.w	1		; color
	dc.w	0,1,2,3,0
	dc.w	4		; face 1
	dc.w	1		; color
	dc.w	4,7,6,5,4
	dc.w	4		; face 2
	dc.w	2		; color
	dc.w	4,0,3,7,4
	dc.w	4		; face 3
	dc.w	2		; color
	dc.w	5,6,2,1,5
	dc.w	4		; face 4
	dc.w	3		; color
	dc.w	5,1,0,4,5
	dc.w	4		; face 5
	dc.w	3		; color
	dc.w	6,7,3,2,6
