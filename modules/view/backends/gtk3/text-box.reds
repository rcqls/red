Red/System [
	Title:	"Text Box Windows DirectWrite Backend"
	Author: "Xie Qingtian, RCqls"
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

#define PANGO_TEXT_MARKUP_SIZED		500

max-line-cnt:  0

layout-ctx-init: func [
	lc 			[layout-ctx!]
	text 		[c-string!]
	text-len	[integer!]
][
	lc/closed-tags: null
	lc/text: text
	lc/text-len: text-len
	lc/text-markup: as handle! g_string_sized_new PANGO_TEXT_MARKUP_SIZED
]

layout-ctx-set-attrs: func [
	lc 			[layout-ctx!]
	attrs 		[handle!]
][
	lc/attrs: attrs
]

pango-open-tag-text: func [
	attr-type	[integer!]
	attr-key	[c-string!]
	attr-val	[int-ptr!]
	text 		[c-string!]
	return: 	[c-string!]
	/local
		format 	[c-string!]
		str		[c-string!]

][
	format: "" str: ""
	str: case [
		attr-type = 1 [ ; c-string!
			format: "<span %s='%s'>%s"
			g_strdup_printf [format attr-key as c-string! attr-val/value  text]
		]	
		attr-type = 2 [ ; integer!
			format: "<span %s='%d'>%s"
			g_strdup_printf [format attr-key attr-val/value  text]
		]
		attr-type = 3 [ ; float!
			format: "<span %s='%f'>%s"
			g_strdup_printf [format attr-key as float! attr-val/value  text]
		]	
	]
	str
]

pango-prepend-closed-tag: func [
	closed-tags [handle!]
	level 		[integer!]
][
	g_list_prepend closed-tags as handle! level
]

pango-last-closed-tag?: func [
	closed-tags [handle!]
	return: 	[integer!]
	/local
		current 	[handle!]
][
	current: g_list_nth_data closed-tags 0
	either null? current [-1][as integer! current]
]

pango-next-closed-tag: func [
	closed-tags [handle!]
	/local
		first 	[handle!]
][
	first: g_list_first closed-tags
	g_list_delete_link closed-tags first
]

pango-add-tag: func [
	lc 			[layout-ctx!]
	attr-type	[integer!]
	attr-key	[c-string!]
	attr-val	[int-ptr!]
	pos 		[integer!]
	len 		[integer!]
	/local
		text 			[c-string!]
		tmp 			[c-string!]
		pos-current-closed-tag 	[integer!]
		pos-last-closed-tag 	[integer!]
][	
	pos-last-closed-tag: pango-last-closed-tag? lc/closed-tags
	pos-current-closed-tag: pos + len
	if any[
		pos-last-closed-tag = -1 
		pos-current-closed-tag >= pos-last-closed-tag
	][
		0
	]

	text: lc/text
	tmp: pango-open-tag-text attr-type attr-key attr-val text
	lc/text-markup
]

pango-close-tag: func [
	lc 			[layout-ctx!]
][
	0
]

; pango-append-enclosed-text: func [
; 	dc		[draw-ctx!]
; 	pos		[integer!]
; 	len		[integer!]
; 	pre 	[c-string!]
; 	post 	[c-string!]
; 	/local
; 		mtext		[c-string!]
; 		tmp			[c-string!]
; ][
; 	tmp: dc/text + pos
; 	tmp: either len = -1 [g_strdup tmp][g_strndup tmp len]
; 	mtext: g_strconcat [dc/text-markup pre tmp post null]
; 	print ["mtext:" mtext lf]
; 	unless null? tmp [g_free as handle! tmp]
; 	print ["mtext:" mtext lf]
; 	;unless pos = 0 [g_free as handle! dc/text-markup]
; 	dc/text-markup: mtext
; 	print ["mtext:" mtext lf]

; ]

int-to-rgba: func [
	color		[integer!]
	r			[int-ptr!]
	b			[int-ptr!]
	g			[int-ptr!]
	a			[int-ptr!]
][
	;; TODO:
	r/value: (color >> 24 and FFh) << 8
	g/value: (color >> 16 and FFh) << 8
	b/value: (color >> 8 and FFh) << 8
	a/value: (color  and FFh) << 8
	print ["color: " color " " r/value "." g/value "." b/value "." a/value lf ]
]

OS-text-box-color: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		lc		[layout-ctx!]
		attr 	[PangoAttribute!]
		r 		[integer!]
		g 		[integer!]
		b 		[integer!]
		a 		[integer!]
][
	lc: as layout-ctx! layout
	print ["OS-text-box-color lc: " lc " lc/attrs: " lc/attrs lf]
	r: 0 g: 0 b: 0 a: 0
	int-to-rgba color :r :g :b :a
	attr: pango_attr_foreground_new r g b
	attr/start: pos attr/end: pos + len
	print ["col[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr

]

OS-text-box-background: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	/local
		lc		[layout-ctx!]
		attr 	[PangoAttribute!]
		r 		[integer!]
		g 		[integer!]
		b 		[integer!]		
		a 		[integer!]
][
	lc: as layout-ctx! layout
	r: 0 g: 0 b: 0 a: 0
	int-to-rgba color :r :g :b :a
	attr: pango_attr_background_new r g b
	attr/start: pos attr/end: pos + len
	print ["bgcol[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr

	;pango-add-tag lc "weight"

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
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	weight	[integer!]
	/local
		lc		[layout-ctx!]
		attr 	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	attr: pango_attr_weight_new weight
	attr/start: pos attr/end: pos + len
	print ["weight[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr

	;pango-add-tag lc "weight"   
]

OS-text-box-italic: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	/local
		lc		[layout-ctx!]
		attr 	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	attr: pango_attr_style_new PANGO_STYLE_ITALIC
	attr/start: pos attr/end: pos + len
	print ["italic[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr
]

OS-text-box-underline: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
	/local
		lc		[layout-ctx!]
		attr 	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	;; TODO: I guess opts would offers the PANGO_UNDERLINE options
	attr: pango_attr_underline_new PANGO_UNDERLINE_SINGLE
	attr/start: pos attr/end: pos + len
	print ["underline[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr 
]

OS-text-box-strikeout: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]
	/local
		lc		[layout-ctx!]
		attr 	[PangoAttribute!]					;-- options
][
	lc: as layout-ctx! layout
	attr: pango_attr_strikethrough_new yes
	attr/start: pos attr/end: pos + len
	print ["strike[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr 
]

OS-text-box-border: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
	/local
		lc		[layout-ctx!]
][
	lc: as layout-ctx! layout
]

OS-text-box-font-name: func [
	dc		[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	name	[red-string!]
	/local
		lc		[layout-ctx!]
		attr	[PangoAttribute!]
		strlen	[integer!]
		str		[c-string!]
		;dctx 	[draw-ctx!]
		fd 		[handle!]
][
	lc: as layout-ctx! layout
	strlen: -1
	str: unicode/to-utf8 name :strlen
	print ["OS-text-box-font-name: " str lf]
	fd: pango_font_description_from_string str
	attr:  pango_attr_font_desc_new fd
	pango_font_description_free fd
	attr/start: pos attr/end: pos + len
	print ["name[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr 
]

OS-text-box-font-size: func [
	nsfont	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	size	[float!]
	/local
		lc		[layout-ctx!]
		attr 	[PangoAttribute!]
][
	lc: as layout-ctx! layout
	print ["OS-text-box-font-size: " size " " as integer! size  lf]
	attr: pango_attr_size_new_absolute as integer! size
	attr/start: pos attr/end: pos + len
	print ["color[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr 
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
		dc 		[draw-ctx!]
		lc 		[layout-ctx!]
		attrs 	[handle!]

		font	[handle!]
		clr		[integer!]
		text	[red-string!]
		len     [integer!]
		str		[c-string!]
][
	lc: declare layout-ctx!
	values: object/get-values box

	text: as red-string! values + FACE_OBJ_TEXT
	len: -1
	str: unicode/to-utf8 text :len
	layout-ctx-init lc str len

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

	print ["OS-text-box-layout: " target lf]

	either null? target [
		null
	][
		dc: as draw-ctx! target
		; copy-cell as red-value! str pval + 3			;-- save text
		attrs: pango_attr_list_new
		layout-ctx-set-attrs lc attrs 
		print ["layout-ctx-set-attrs: " lc " " attrs lf]
		; handle/make-at pval as-integer layout

		styles: as red-block! values + FACE_OBJ_DATA
		if all [
			TYPE_OF(styles) = TYPE_BLOCK
			1 < block/rs-length? styles
		][
			parse-text-styles target as handle! lc styles 7FFFFFFFh catch?
		]
		as handle! lc
	]
]