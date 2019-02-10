Red/System [
	Title:	"Text Box Windows DirectWrite Backend"
	Author: "Xie Qingtian"
	File: 	%text-box.reds
	Tabs: 	4
	Dependency: %draw-d2d.reds
	Rights: "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define TBOX_METRICS_OFFSET?		0
#define TBOX_METRICS_INDEX?			1
#define TBOX_METRICS_LINE_HEIGHT	2
#define TBOX_METRICS_METRICS		3

max-line-cnt:  0

OS-text-box-color: func [
	dc		[handle!]
	attrs	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		attr 	[PangoAttribute!]
][
	;attr: pango_attr_foreground_new
	;pango_attr_list_insert attrs attr
]

OS-text-box-background: func [
	dc		[handle!]
	attrs	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		cache	[red-vector!]
		brush	[integer!]
][

	;attr: pango_attr_background_new
	;pango_attr_list_insert attrs attr

	;cache: as red-vector! dc + 3
	;if TYPE_OF(cache) <> TYPE_VECTOR [
	;	vector/make-at as red-value! cache 128 TYPE_INTEGER 4
	;]
	;brush: select-brush dc + 1 color
	;if zero? brush [
	;	this: as this! dc/value
	;	rt: as ID2D1HwndRenderTarget this/vtbl
	;	rt/CreateSolidColorBrush this to-dx-color color null null :brush
	;	put-brush dc + 1 color brush
	;]
	;vector/rs-append-int cache pos
	;vector/rs-append-int cache len
	;vector/rs-append-int cache brush
]

OS-text-box-weight: func [
	attrs	[handle!]
	pos		[integer!]
	len		[integer!]
	weight	[integer!]
	/local
		attr 	[PangoAttribute!]
][
	attr: pango_attr_weight_new weight
	attr/start: pos attr/end: pos + len
	pango_attr_list_insert attrs attr
]

OS-text-box-italic: func [
	attrs	[handle!]
	pos		[integer!]
	len		[integer!]
	/local
		attr 	[PangoAttribute!]
][
	attr: pango_attr_style_new PANGO_STYLE_ITALIC
	attr/start: pos attr/end: pos + len
	pango_attr_list_insert attrs attr
]

OS-text-box-underline: func [
	attrs	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
	/local
		attr 	[PangoAttribute!]
][
	;; TODO: I guess opts would offers the PANGO_UNDERLINE options
	attr: pango_attr_underline_new PANGO_UNDERLINE_SINGLE
	attr/start: pos attr/end: pos + len
	pango_attr_list_insert attrs attr 
]

OS-text-box-strikeout: func [
	attrs	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]
	/local
		attr 	[PangoAttribute!]					;-- options
][
	attr: pango_attr_strikethrough_new yes
	attr/start: pos attr/end: pos + len
	pango_attr_list_insert attrs attr 
]

OS-text-box-border: func [
	attrs	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
][
	0
]

OS-text-box-font-name: func [
	nsfont	[handle!]
	attrs	[handle!]
	pos		[integer!]
	len		[integer!]
	name	[red-string!]
	/local 
		attr	[PangoAttribute!]
		strlen		[integer!]
		str		[c-string!]
][
	strlen: -1
	str: unicode/to-utf8 name :strlen
	attr:  pango_attr_family_new str
	attr/start: pos attr/end: pos + len
	pango_attr_list_insert attrs attr 
]

OS-text-box-font-size: func [
	nsfont	[handle!]
	attrs	[handle!]
	pos		[integer!]
	len		[integer!]
	size	[float!]
	/local
		attr 	[PangoAttribute!]
][
	attr: pango_attr_size_new as integer! size
	attr/start: pos attr/end: pos + len
	pango_attr_list_insert attrs attr 
]

OS-text-box-metrics: func [
	state	[red-block!]
	arg0	[red-value!]
	type	[integer!]
	return: [red-value!]
][
	as red-value! none-value
	;as red-value! switch type [
	;	TBOX_METRICS_OFFSET? [
	;		x: as float32! 0.0 y: as float32! 0.0
	;		;int: as red-integer! arg0
	;	]
	;	TBOX_METRICS_INDEX? [
	;		pos: as red-pair! arg0
	;		x: as float32! pos/x
	;		y: as float32! pos/y
	;	]
	;	TBOX_METRICS_LINE_HEIGHT [
	;		lineCount: 0
	;		dl/GetLineMetrics this null 0 :lineCount
	;		if lineCount > max-line-cnt [
	;			max-line-cnt: lineCount + 1
	;			line-metrics: as DWRITE_LINE_METRICS realloc
	;				as byte-ptr! line-metrics
	;				lineCount + 1 * size? DWRITE_HIT_TEST_METRICS
	;		]
	;		lineCount: 0
	;		dl/GetLineMetrics this line-metrics max-line-cnt :lineCount
	;		lm: line-metrics
	;		hr: as-integer arg0
	;		while [
	;			hr: hr - lm/length
	;			lineCount: lineCount - 1
	;			all [hr > 0 lineCount > 0]
	;		][
	;			lm: lm + 1
	;		]
	;		integer/push as-integer lm/height
	;	]
	;	default [
	;		metrics: as DWRITE_TEXT_METRICS :left
	;		hr: dl/GetMetrics this metrics
	;		#if debug? = yes [if hr <> 0 [log-error hr]]

	;		values: object/get-values as red-object! arg0
	;		integer/make-at values + TBOX_OBJ_WIDTH as-integer metrics/width
	;		integer/make-at values + TBOX_OBJ_HEIGHT as-integer metrics/height
	;		integer/make-at values + TBOX_OBJ_LINE_COUNT metrics/lineCount
	;	]
	;]
]

OS-text-box-layout: func [
	box		[red-object!]
	target	[int-ptr!]
	ft-clr	[integer!]
	catch?	[logic!]
	return: [handle!]
	/local
		hWnd	[handle!]
		values	[red-value!]
		size	[red-pair!]
		int		[red-integer!]
		bool	[red-logic!]
		state	[red-block!]
		styles	[red-block!]
		pval	[red-value!]
		vec		[red-vector!]
		obj		[red-object!]
		w		[integer!]
		h		[integer!]
		attrs	[handle!]

		font	[handle!]
		clr		[integer!]
		text	[red-string!]
		len     [integer!]
		str		[c-string!]
][
	values: object/get-values box

	text: as red-string! values + FACE_OBJ_TEXT
	len: -1
	str: unicode/to-utf8 text :len

	state: as red-block! values + FACE_OBJ_EXT3
	; fmt: as this! create-text-format as red-object! values + FACE_OBJ_FONT

	; ; if null? target [
	; 	hWnd: face-handle? box
	; 	if null? hWnd [
	; 		if null? hidden-hwnd [
	; 			hidden-hwnd: CreateWindowEx WS_EX_TOOLWINDOW #u16 "RedBaseInternal" null WS_POPUP 0 0 2 2 null null hInstance null
	; 			store-face-to-hWnd hidden-hwnd box
	; 		]
	; 		hWnd: hidden-hwnd
	; 	]
	; 	target: get-hwnd-render-target hWnd
	; ]

	; either TYPE_OF(state) = TYPE_BLOCK [
	; 	pval: block/rs-head state
	; 	int: as red-integer! pval
	; 	layout: as this! int/value
	; 	COM_SAFE_RELEASE(IUnk layout)		;-- release previous text layout
	; 	int: int + 1
	; 	old-fmt: as this! int/value
	; 	if old-fmt <> fmt [
	; 		COM_SAFE_RELEASE(IUnk old-fmt)
	; 		int/value: as-integer fmt
	; 	]
	; 	bool: as red-logic! int + 3
	; 	bool/value: false
	; ][
	; 	block/make-at state 5
	; 	none/make-in state							;-- 1: text layout
	; 	handle/make-in state as-integer fmt			;-- 2: text format
	; 	handle/make-in state 0						;-- 3: target
	; 	none/make-in state							;-- 4: text
	; 	logic/make-in state false					;-- 5: layout?
	; 	pval: block/rs-head state
	; ]

	; handle/make-at pval + 2 as-integer target
	; vec: as red-vector! target/4
	; if vec <> null [vector/rs-clear vec]

	; set-text-format fmt as red-object! values + FACE_OBJ_PARA
	; set-tab-size fmt as red-integer! values + FACE_OBJ_EXT1
	; set-line-spacing fmt as red-integer! values + FACE_OBJ_EXT2

	; str: as red-string! values + FACE_OBJ_TEXT
	; size: as red-pair! values + FACE_OBJ_SIZE
	; either TYPE_OF(size) = TYPE_PAIR [
	; 	w: size/x h: size/y
	; ][
	; 	w: 0 h: 0
	; ]

	; copy-cell as red-value! str pval + 3			;-- save text
	attrs: pango_attr_list_new ; str fmt w h
	; handle/make-at pval as-integer layout

	styles: as red-block! values + FACE_OBJ_DATA
	if all [
		TYPE_OF(styles) = TYPE_BLOCK
		1 < block/rs-length? styles
	][
		parse-text-styles target attrs styles 7FFFFFFFh catch?
	]
	attrs
]