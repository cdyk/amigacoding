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

edge_N		equ	12

edges:
	dc.w	0,1
	dc.w	1,2
	dc.w	2,3
	dc.w	3,0

	dc.w	4,5
	dc.w	5,6
	dc.w	6,7
	dc.w	7,4

	dc.w	0,4
	dc.w	1,5
	dc.w	2,6
	dc.w	3,7