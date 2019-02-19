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

pango-opt-tag!: alias struct! [
	opt 	[c-string!]
	pos 	[integer!]
	len		[integer!]
]

pango-compare-tag: func [
	[cdecl] 
	tag1 	[pango-opt-tag!] 
	tag2 	[pango-opt-tag!] 
	return:	[integer!]
	/local
		comp 	[integer!]
][
	;; DEBUG: print ["pango-compare-tag: (" tag1/pos "," tag1/len "," tag1/opt ") and ("  tag2/pos "," tag2/len "," tag2/opt  ") -> " ]
	either tag1/pos = tag2/pos [
		either tag1/len = tag2/len [comp: 0][
			comp: either tag1/len > tag2/len [-1][1]
		]
	][
		comp: either tag1/pos > tag2/pos [1][-1]
	]
	comp
]

make-pango-opt-tag: func [
	opt 	[c-string!]
	pos		[integer!]
	len		[integer!]
	return:	[handle!]
	/local
		tag 	[pango-opt-tag!]
][
	tag: as pango-opt-tag! allocate size? pango-opt-tag!
	tag/opt: opt tag/pos: pos tag/len: len
	as handle! tag
]

pango-insert-tag: func [
	lc 		[layout-ctx!]
	opt 	[c-string!]
	pos		[integer!]
	len		[integer!]
	/local
		tag 	[handle!]
		tag2 	[handle!]
][
	tag: make-pango-opt-tag opt pos len
	;; DEBUG: print ["insert tag: " tag  lf ]; "<span " tag/opt "> at (" tag/pos "," tag/len ")" lf ]
	lc/tag-list: g_list_insert_sorted lc/tag-list tag as-integer :pango-compare-tag
]

layout-ctx-begin: func [
	lc 			[layout-ctx!]
	text 		[c-string!]
	text-len	[integer!]
][
	lc/closed-tags: null
	lc/text: text
	lc/text-len: text-len
	lc/text-pos: 0
	lc/text-markup: as handle! g_string_sized_new PANGO_TEXT_MARKUP_SIZED
	g_string_assign as GString! lc/text-markup "<markup>"
	lc/tag-list: null
]


layout-ctx-set-attrs: func [
	lc 			[layout-ctx!]
	attrs 		[handle!]
][
	lc/attrs: attrs
]

pango-add-open-tag: func [
	lc 			[layout-ctx!]
	open-tag	[c-string!]
	/local
		gstr		[GString!]
][
	gstr: as GString! lc/text-markup
	g_string_append gstr "<span "
	g_string_append gstr open-tag
	g_string_append gstr ">"
	g_free as handle! open-tag
]

pango-open-tag-string?: func [
	lc 			[layout-ctx!]
	attr-key	[c-string!]
	attr-val	[c-string!]
	return: 	[c-string!]
	/local
		str		[c-string!]
][
	str: ""
	str: g_strdup_printf ["%s='%s'" attr-key attr-val]
	str
]

pango-open-tag-int?: func [
	lc 			[layout-ctx!]
	attr-key	[c-string!]
	attr-val	[integer!]
	return: 	[c-string!]
	/local
		str		[c-string!]
][
	str: ""
	str: g_strdup_printf ["%s='%d'" attr-key attr-val]
	str
]

pango-open-tag-float?: func [
	lc 			[layout-ctx!]
	attr-key	[c-string!]
	attr-val	[float!]
	return: 	[c-string!]
	/local
		str		[c-string!]
][
	str: ""
	str: g_strdup_printf ["%s='%f'" attr-key attr-val]
 	str
]

pango-add-closed-tag: func [
	lc 			[layout-ctx!]
	level 		[integer!]
][
	lc/closed-tags: g_list_prepend lc/closed-tags as int-ptr! level
]

pango-last-closed-tag?: func [ ; last in time not in the GList
	lc 			[layout-ctx!]
	return: 	[integer!]
	/local
		current 	[int-ptr!]
][
	current: g_list_nth_data lc/closed-tags 0
	either null? current [-1][as integer! current]
]

pango-next-closed-tag: func [
	lc 		[layout-ctx!]
	/local
		first 	[handle!]
][
	first: g_list_first lc/closed-tags
	lc/closed-tags: g_list_delete_link lc/closed-tags first
]

pango-close-tags: func [
	lc					[layout-ctx!]
	pos-last-closed-tag	[integer!]
	/local
		text-len		[integer!]
][
	if pos-last-closed-tag = -1 [pos-last-closed-tag: length? lc/text]
	text-len: pos-last-closed-tag - lc/text-pos
	print ["pango-close-tags -> append: (" text-len ")" lc/text + lc/text-pos  lf]
	g_string_append_len as GString! lc/text-markup lc/text + lc/text-pos text-len
	lc/text-pos: lc/text-pos + text-len
	; Add closed tags
	print ["close-tags: " pos-last-closed-tag " "  pango-last-closed-tag? lc lf]
	while [ pos-last-closed-tag = pango-last-closed-tag? lc ][
		print ["close-tags: </span>" lf]
		g_string_append as GString! lc/text-markup "</span>"
		pango-next-closed-tag lc
	]
]

pango-process-closed-tags: func [
	lc 			[layout-ctx!]
	pos 		[integer!]
	len 		[integer!]
	/local
		text 					[c-string!]
		tmp 					[c-string!]
		pos-current-closed-tag 	[integer!]
		pos-last-closed-tag 	[integer!]
][	
	pos-last-closed-tag: pango-last-closed-tag? lc
	pos-current-closed-tag: pos + len
	print ["process closed tags: current=" pos-current-closed-tag " last=" pos-last-closed-tag lf]
	; Close tags with text first if any
	if all[
		pos-last-closed-tag <> -1 
		pos-current-closed-tag > pos-last-closed-tag
	][
		pango-close-tags lc pos-last-closed-tag
	]
]

pango-process-tag: func [
	lc 			[layout-ctx!]
	open-tag	[c-string!]
	pos 		[integer!]
	len 		[integer!]
][
	pango-process-closed-tags lc pos len
	pango-add-open-tag lc open-tag
	pango-add-closed-tag lc pos + len
]

pango-markup-text: func [
	lc 			[layout-ctx!]
	/local
		gl		[GList!]
		last	[GList!]
		tag		[pango-opt-tag!]
		len		[integer!]
		pos		[integer!]
		opt		[c-string!]
		text		[GString!]
][
	
	last: as GList! g_list_last lc/tag-list

	gl: as GList! g_list_first lc/tag-list
	until [
		tag: as pango-opt-tag! gl/data
		print ["<span "  tag/opt "> at (" tag/pos "," tag/pos + tag/len - 1 ")" lf]
		gl: gl/next
		null? gl
	]

	gl: as GList! g_list_first lc/tag-list

	lc/text-pos: 0 lc/closed-tags: null
	g_string_assign as GString! lc/text-markup "<markup>"
	until [
		tag: as pango-opt-tag! gl/data
		;;print ["<span "  tag/opt "> at (" tag/pos "," tag/len ")" lf]
		pango-process-closed-tags lc tag/pos tag/len
		pango-add-open-tag lc tag/opt
		pango-add-closed-tag lc tag/pos + tag/len
		
		gl: gl/next
		null? gl
	]
	pango-close-tags lc -1
	text: as GString! lc/text-markup
	g_string_append  text "</markup>"
	print ["tex-markup: " text/str lf]

]

layout-ctx-end: func [
	lc 			[layout-ctx!]
	/local
		text		[GString!]
][
	pango-close-tags lc -1
	text: as GString! lc/text-markup
	g_string_append  text "</markup>"
	print ["tex-markup: " text/str lf]
	; TODO: free everything not anymore used
	pango-markup-text lc
]

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

int-to-rgba-hex: func [
	color		[integer!]
	return: 	[c-string!]
	/local
		r			[integer!]
		b			[integer!]
		g			[integer!]
		a			[integer!]
][
	a: (color >> 24 and FFh) 
	r: (color >> 16 and FFh) 
	g: (color >> 8 and FFh) 
	b: (color  and FFh)
	color: (b << 24 and FF000000h) or (g << 16  and 00FF0000h) or ( r << 8 and FF00h) or ( a and FFh)
	; print ["color rgba: " color " " r "." g "." b "." a lf ]
	; print ["col(#" string/to-hex r yes string/to-hex g yes string/to-hex b yes  string/to-hex a yes ")" lf]
	print ["col(#" string/to-hex color no ")" lf]
	g_strdup_printf ["#%s" string/to-hex  color no]
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
		rgba	[c-string!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout
	print ["OS-text-box-color lc: " lc " lc/attrs: " lc/attrs lf]
	r: 0 g: 0 b: 0 a: 0
	int-to-rgba color :r :g :b :a
	attr: pango_attr_foreground_new r g b
	attr/start: pos attr/end: pos + len
	pango_attr_list_insert lc/attrs attr

	rgba: int-to-rgba-hex color
	print ["col(" rgba ")[" pos "," pos + len - 1 "]" lf]
	
	ot: pango-open-tag-string? lc "color" rgba
	pango-process-tag lc ot pos len

	ot: pango-open-tag-string? lc "color" rgba
	pango-insert-tag lc ot pos len
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
		rgba	[c-string!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout
	r: 0 g: 0 b: 0 a: 0
	int-to-rgba color :r :g :b :a
	attr: pango_attr_background_new r g b
	attr/start: pos attr/end: pos + len
	print ["bgcol[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr

	rgba: int-to-rgba-hex color
	print ["bgcol(" rgba ")[" pos "," pos + len - 1 "]" lf]
	
	ot: pango-open-tag-string? lc "bgcolor" rgba
	pango-process-tag lc ot pos len

	ot: pango-open-tag-string? lc "bgcolor" rgba
	pango-insert-tag lc ot pos len

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
		ot		[c-string!]
][
	lc: as layout-ctx! layout
	attr: pango_attr_weight_new weight
	attr/start: pos attr/end: pos + len
	print ["weight[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr

	
	ot: pango-open-tag-int? lc "weight" weight pos len
	pango-process-tag lc ot pos len

	ot: pango-open-tag-int? lc "weight" weight pos len
	pango-insert-tag lc ot pos len

]

OS-text-box-italic: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	/local
		lc		[layout-ctx!]
		attr 	[PangoAttribute!]
		ot		[c-string!]
][
	lc: as layout-ctx! layout
	attr: pango_attr_style_new PANGO_STYLE_ITALIC
	attr/start: pos attr/end: pos + len
	print ["italic[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr
	
	ot: pango-open-tag-string? lc "style" "italic"
	pango-process-tag lc ot pos len

	ot: pango-open-tag-string? lc "style" "italic"
	pango-insert-tag lc ot pos len
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
		ot		[c-string!]
][
	lc: as layout-ctx! layout
	;; TODO: I guess opts would offers the PANGO_UNDERLINE options
	attr: pango_attr_underline_new PANGO_UNDERLINE_SINGLE
	attr/start: pos attr/end: pos + len
	print ["underline[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr 

	ot: pango-open-tag-string? lc "underline" "single"
	pango-process-tag lc ot pos len

	ot: pango-open-tag-string? lc "underline" "single"
	pango-insert-tag lc ot pos len
]

OS-text-box-strikeout: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]
	/local
		lc		[layout-ctx!]
		attr 	[PangoAttribute!]					;-- options
		ot		[c-string!]
][
	lc: as layout-ctx! layout
	attr: pango_attr_strikethrough_new yes
	attr/start: pos attr/end: pos + len
	print ["strike[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr
	
	ot: pango-open-tag-string? lc "strikethrough" "true"
	pango-process-tag lc ot pos len

	ot: pango-open-tag-string? lc "strikethrough" "true"
	pango-insert-tag lc ot pos len
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
		ot		[c-string!]
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
	
	ot: pango-open-tag-string? lc "face" str
	pango-process-tag lc ot pos len

	ot: pango-open-tag-string? lc "face" str
	pango-insert-tag lc ot pos len
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
		ot		[c-string!]
][
	lc: as layout-ctx! layout
	print ["OS-text-box-font-size: " size " " as integer! size  lf]
	attr: pango_attr_size_new_absolute as integer! size
	attr/start: pos attr/end: pos + len
	print ["size[" pos "," pos + len - 1 "]" lf]
	pango_attr_list_insert lc/attrs attr
	
	ot: pango-open-tag-int? lc "font" as integer! size
	pango-process-tag lc ot pos len

	ot: pango-open-tag-int? lc "font" as integer! size
	pango-insert-tag lc ot pos len
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
	layout-ctx-begin lc str len

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
		layout-ctx-end lc
		as handle! lc
	]
]