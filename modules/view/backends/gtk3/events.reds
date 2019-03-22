Red/System [
	Title:	"GTK3 events handling"
	Author: "Qingtian Xie, RCqls"
	File: 	%events.reds
	Tabs: 	4
	Rights: "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;; In the GTK world, gboolean is a gint and the dispatching is as follows:
#enum event-action! [
	EVT_DISPATCH: 0										;-- allow DispatchMessage call only
	EVT_NO_DISPATCH 									;-- no further msg processing allowed
]

#define GDK_BUTTON_PRIMARY 1
#define GDK_BUTTON_MIDDLE 2
#define GDK_BUTTON_SECONDARY 3

gui-evt: declare red-event!								;-- low-level event value slot
gui-evt/header: TYPE_EVENT

modal-loop-type: 0										;-- remanence of last EVT_MOVE or EVT_SIZE
zoom-distance:	 0
special-key: 	-1										;-- <> -1 if a non-displayable key is pressed

flags-blk: declare red-block!							;-- static block value for event/flags
flags-blk/header:	TYPE_BLOCK
flags-blk/head:		0
flags-blk/node:		alloc-cells 4

; used to save old position of pointer in widget-motion-notify-event handler
evt-motion: context [
	state:		no
	x_root:		0.0
	y_root:		0.0
	x_new:	 	0
	y_new:		0
	cpt:		0
	sensitiv:	3
]

evt-sizing: context [
	x_root:		0.0
	y_root:		0.0
	x_new: 		0
	y_new: 		0
]
make-at: func [
	widget	[handle!]
	face	[red-object!]
	return: [red-object!]
	/local
		f	[red-value!]
][
	f: as red-value! g_object_get_qdata widget red-face-id
	assert f <> null
	as red-object! copy-cell f as cell! face
]

push-face: func [
	handle  [handle!]
	return: [red-object!]
][
	make-at handle as red-object! stack/push*
]

get-event-face: func [
	evt		[red-event!]
	return: [red-value!]
][
	as red-value! push-face as handle! evt/msg
]

get-event-window: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		handle [handle!]
		face   [red-object!]
][
	none-value
]

get-event-offset: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		widget	[handle!]
		sz 		[red-pair!]
		offset	[red-pair!]
		value	[integer!]
][
	;; DEBUG: print ["get-event-offset: " evt/type lf]
	case [
		any [
			evt/type <= EVT_OVER
			evt/type = EVT_MOVING
			evt/type = EVT_MOVE
		][
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
			offset/x: evt-motion/x_new
			offset/y: evt-motion/y_new
			;; DEBUG: print ["event-offset: " offset/x "x" offset/y lf]
			as red-value! offset
		]
		any [
			evt/type = EVT_SIZING
			evt/type = EVT_SIZE
		][
			;; DEBUG: print ["event-offset type: " get-symbol-name get-widget-symbol widget lf]
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR

			widget: as handle! evt/msg
			sz: (as red-pair! get-face-values widget) + FACE_OBJ_SIZE
			sz/x: evt-sizing/x_new
			sz/y: evt-sizing/y_new
			
			; print ["OFFSET is SIZE ? " sz " vs " offset lf] ; => NO!
			; alternative 1:
 			; sz/x: (as integer! evt-sizing/x_root) - offset/x
			; sz/y: (as integer! evt-sizing/y_root)  - offset/y 

			; alternative 2:
			; sz/x: gtk_widget_get_allocated_width widget
			; sz/y: gtk_widget_get_allocated_height widget

			;; DEBUG: print ["event-size: " sz/x "x" sz/y " vs " offset/x "x" offset/y lf]
			as red-value! sz
		]
		any [
			evt/type = EVT_ZOOM
			evt/type = EVT_PAN
			evt/type = EVT_ROTATE
			evt/type = EVT_TWO_TAP
			evt/type = EVT_PRESS_TAP
		][

			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
			as red-value! offset
		]
		evt/type = EVT_MENU [
			offset: as red-pair! stack/push*
			offset/header: TYPE_PAIR
			offset/x: menu-x
			offset/y: menu-y
			as red-value! offset
		]
		true [as red-value! none-value]
	]
]

get-event-key: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		char 		[red-char!]
		code 		[integer!]
		res	 		[red-value!]
		special?	[logic!]
][
	as red-value! switch evt/type [
		EVT_KEY
		EVT_KEY_UP
		EVT_KEY_DOWN [
			res: null
			code: evt/flags
			special?: code and 80000000h <> 0
			code: code and FFFFh
			;; DEBUG: 
			print ["key-code=" code " flags=" evt/flags " special?=" special? lf]
			if special? [
				res: as red-value! switch code [
					RED_VK_PRIOR	[_page-up]
					RED_VK_NEXT		[_page-down]
					RED_VK_END		[_end]
					RED_VK_HOME		[_home]
					RED_VK_LEFT		[_left]
					RED_VK_UP		[_up]
					RED_VK_RIGHT	[_right]
					RED_VK_DOWN		[_down]
					RED_VK_INSERT	[_insert]
					RED_VK_DELETE	[_delete]
					RED_VK_F1		[_F1]
					RED_VK_F2		[_F2]
					RED_VK_F3		[_F3]
					RED_VK_F4		[_F4]
					RED_VK_F5		[_F5]
					RED_VK_F6		[_F6]
					RED_VK_F7		[_F7]
					RED_VK_F8		[_F8]
					RED_VK_F9		[_F9]
					RED_VK_F10		[_F10]
					RED_VK_F11		[_F11]
					RED_VK_F12		[_F12]
					RED_VK_LSHIFT	[_left-shift]
					RED_VK_RSHIFT	[_right-shift]
					RED_VK_LCONTROL	[_left-control]
					RED_VK_RCONTROL	[_right-control]
					RED_VK_LMENU	[_left-alt]
					RED_VK_RMENU	[_right-alt]
					RED_VK_LWIN		[_left-command]
					RED_VK_APPS		[_right-command]
					default			[null]
				]
			]
			either null? res [
				either all [special? evt/type = EVT_KEY][
					none-value
				][
					char: as red-char! stack/push*
					char/header: TYPE_CHAR
					char/value: code
					as red-value! char
				]
			][res]
		]
		default [as red-value! none-value]
	]
]

get-event-picked: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		res [red-value!]
		int	[red-integer!]
		pct [red-float!]
		zd	[float!]
][
	as red-value! switch evt/type [
		EVT_ZOOM
		EVT_PAN
		EVT_ROTATE
		EVT_TWO_TAP
		EVT_PRESS_TAP [
			either evt/type = EVT_ZOOM [
				res: as red-value! none/push
			][
				int: as red-integer! stack/push*
				int/header: TYPE_INTEGER
				int
			]
		]
		EVT_MENU [word/push* evt/flags and FFFFh]
		default	 [integer/push evt/flags and FFFFh]
	]
]

get-event-flags: func [
	evt		[red-event!]
	return: [red-value!]
	/local
		blk [red-block!]
][
	;; DEBUG: print ["get-event-flags: " evt/flags lf]
	blk: flags-blk
	block/rs-clear blk	
	if evt/flags and EVT_FLAG_AWAY		 <> 0 [block/rs-append blk as red-value! _away]
	if evt/flags and EVT_FLAG_DOWN		 <> 0 [block/rs-append blk as red-value! _down]
	if evt/flags and EVT_FLAG_MID_DOWN	 <> 0 [block/rs-append blk as red-value! _mid-down]
	if evt/flags and EVT_FLAG_ALT_DOWN	 <> 0 [block/rs-append blk as red-value! _alt-down]
	if evt/flags and EVT_FLAG_AUX_DOWN	 <> 0 [block/rs-append blk as red-value! _aux-down]
	if evt/flags and EVT_FLAG_CTRL_DOWN	 <> 0 [block/rs-append blk as red-value! _control]
	if evt/flags and EVT_FLAG_SHIFT_DOWN <> 0 [block/rs-append blk as red-value! _shift]
	as red-value! blk
]

get-event-flag: func [
	flags	[integer!]
	flag	[integer!]
	return: [red-value!]
][
	as red-value! logic/push flags and flag <> 0
]

;; This function is only called in handlers.red
;; No 
make-event: func [
	msg		[handle!]
	flags	[integer!]
	evt		[integer!]
	return: [integer!]
	/local
		res	   [red-word!]
		word   [red-word!]
		sym	   [integer!]
		state  [integer!]
		key	   [integer!]
		char   [integer!]
		type   [integer!]
][
	gui-evt/type:  evt
	gui-evt/msg:   as byte-ptr! msg
	gui-evt/flags: flags

	;; DEBUG: print ["make-event:  down? " flags and EVT_FLAG_DOWN <> 0 lf]

	state: EVT_DISPATCH

	switch evt [
		; EVT_OVER [0
		; ]
		; EVT_KEY_DOWN [0
		; ]
		; EVT_KEY_UP [0
		; ]
		; EVT_KEY [0
		; ]
		; EVT_SELECT [0
		; ]
		; EVT_CHANGE [0
		; ]
		EVT_LEFT_DOWN [
			case [
				flags and EVT_FLAG_DBL_CLICK <> 0 [
					;; DEBUG: print ["Double click!!!!!" lf]
					gui-evt/type: EVT_DBL_CLICK
				]
				; flags and EVT_FLAG_CMD_DOWN <> 0 [
				; 	gui-evt/type: EVT_RIGHT_DOWN
				; ]
				; flags and EVT_FLAG_CTRL_DOWN <> 0 [
				; 	gui-evt/type: EVT_MIDDLE_DOWN
				; ]
				true [0]
			]
		]
		; EVT_LEFT_UP [
		; 	case [
		; 		flags and EVT_FLAG_CMD_DOWN <> 0 [
		; 			gui-evt/type: EVT_RIGHT_UP
		; 		]
		; 		flags and EVT_FLAG_CTRL_DOWN <> 0 [
		; 			gui-evt/type: EVT_MIDDLE_UP
		; 		]
		; 		true [0]
		; 	]
		; ]
		; EVT_CLICK [0
		; ]
		; EVT_MENU [0]		;-- symbol ID of the menu
		default	 [0]
	]

	stack/mark-try-all words/_anon
	res: as red-word! stack/arguments
	catch CATCH_ALL_EXCEPTIONS [
		#call [system/view/awake gui-evt]
		stack/unwind
	]
	stack/adjust-post-try
	if system/thrown <> 0 [system/thrown: 0]
	;; DEBUG: print ["make-event result:" res lf]
	type: TYPE_OF(res)
	if  ANY_WORD?(type) [
		sym: symbol/resolve res/symbol
		;; DEBUG: print ["make-event symbol:" get-symbol-name sym lf]
		case [
			sym = done [state: EVT_DISPATCH]			;-- prevent other high-level events
			sym = stop [state: EVT_NO_DISPATCH]			;-- prevent all other events
			true 	   [0]								;-- ignore others
		]
	]

	; #call [system/view/awake gui-evt]
	; res: as red-word! stack/arguments

	; if TYPE_OF(res) = TYPE_WORD [
	; 	sym: symbol/resolve res/symbol
	; 	;; DEBUG: 
	; 	print ["make-events result:" sym lf]

	; 	case [
	; 		sym = done [state: EVT_DISPATCH]			;-- prevent other high-level events
	; 		sym = stop [state: EVT_NO_DISPATCH]			;-- prevent all other events
	; 		true 	   [0]								;-- ignore others
	; 	]
	; ]

	state
]

;; DEBUG: evt-cpt: 0

do-events: func [
	no-wait? [logic!]
	return:  [logic!]
	/local
		msg? [logic!]
		;; DEBUG
		event	[GdkEventAny!]
		widget	[handle!]
		; state	[GdkModifierType!]
		; source	[handle!]
][
	msg?: no
	;; DEBUG: state: 0

	;@@ Improve it!!!
	;@@ as we cannot access gapplication->priv->use_count
	;@@ we use a global value to simulate it
	unless no-wait? [exit-loop: exit-loop + 1]

	while [exit-loop > 0][
		;; DEBUG: evt-cpt: evt-cpt + 1
		;; DEBUG: 
		; print ["owner " GTKApp-Ctx "  " g_main_context_is_owner GTKApp-Ctx lf]
		; source: g_main_current_source 
		; print ["source: " source lf]
		; gtk_get_current_event_state :state
		; print ["state: " state lf]
		; print ["time: " gtk_get_current_event_time lf]
		;; DEBUG: event: as GdkEventAny! gtk_get_current_event
		;; DEBUG: print ["do-events " evt-cpt " -> event: " event lf]
		; widget: gtk_get_event_widget event	
		; print ["event widget: " widget lf]
		if g_main_context_iteration GTKApp-Ctx not no-wait? [msg?: yes]
		if no-wait? [break]
	]
	
	while [g_main_context_iteration GTKApp-Ctx false][	;-- consume leftover event
		msg?: yes
		if no-wait? [break]
	]
	
	;g_settings_sync
	;; UNCOMMENTING THE NEXT LINE makes ballots.red failing at least for the 3rd window
	;g_main_context_release GTKApp-Ctx			;@@ release it?
	;; UNCOMMENTING THE NEXT LINE generates an ERROR
	;g_object_unref GTKApp
	msg?
]

check-extra-keys: func [
	state	[integer!]
	return: [integer!]
	/local
		key		[integer!]
][
	key: 0
	if state and GDK_SHIFT_MASK <> 0 [key: EVT_FLAG_SHIFT_DOWN]
	if state and GDK_CONTROL_MASK <> 0 [key: key or EVT_FLAG_CTRL_DOWN]
	if any [state and GDK_MOD1_MASK <> 0  state and GDK_MOD5_MASK <> 0][key: key or EVT_FLAG_MENU_DOWN]
	key
]

check-extra-buttons: func [
	state	[integer!]
	return:	[integer!]
	/local
		buttons	[integer!]
][
	buttons: 0
	if state and GDK_BUTTON1_MASK  <> 0 [buttons: EVT_FLAG_DOWN]
	if state and GDK_BUTTON2_MASK  <> 0 [buttons: buttons or EVT_FLAG_DOWN]
	if state and GDK_BUTTON3_MASK  <> 0 [buttons: buttons or EVT_FLAG_DOWN]
	buttons
]

check-down-flags: func [
	state  [integer!]
	return: [integer!]
	/local
		flags [integer!]
][
	flags: 0
	if state and GDK_BUTTON1_MASK <> 0 [flags: flags or EVT_FLAG_DOWN]
	if state and GDK_META_MASK <> 0 [flags: flags or EVT_FLAG_ALT_DOWN]
	if state and GDK_SHIFT_MASK <> 0 [flags: flags or EVT_FLAG_SHIFT_DOWN]
	if state and GDK_CONTROL_MASK <> 0 [flags: flags or EVT_FLAG_CTRL_DOWN]
	if state and GDK_BUTTON2_MASK <> 0 [flags: flags or EVT_FLAG_MID_DOWN]
	if state and GDK_BUTTON3_MASK <> 0 [flags: flags or EVT_FLAG_AUX_DOWN]
	;;if state and 0040h <> 0 [flags: flags or EVT_FLAG_AUX_DOWN]	;-- needs an AUX2 flag
	flags
]

check-flags: func [
	type   	[integer!]
	state  	[integer!]
	return: [integer!]
	/local
		flags [integer!]
][
	flags: 0
	;;[flags: flags or EVT_FLAG_AX2_DOWN]
	if state and GDK_META_MASK <> 0 [flags: flags or EVT_FLAG_AUX_DOWN]
	if state and GDK_META_MASK <> 0 [flags: flags or EVT_FLAG_ALT_DOWN]
	if state and GDK_BUTTON2_MASK <> 0 [flags: flags or EVT_FLAG_MID_DOWN]
	if state and GDK_BUTTON1_MASK <> 0 [flags: flags or EVT_FLAG_DOWN]
	;;[flags: flags or EVT_FLAG_AWAY]
	if type = GDK_DOUBLE_BUTTON_PRESS [flags: flags or EVT_FLAG_DBL_CLICK]
	if state and GDK_CONTROL_MASK <> 0 [flags: flags or EVT_FLAG_CTRL_DOWN]
	if state and GDK_SHIFT_MASK <> 0 [flags: flags or EVT_FLAG_SHIFT_DOWN]
	if state and GDK_HYPER_MASK <> 0 [flags: flags or EVT_FLAG_MENU_DOWN]
	if state and GDK_SUPER_MASK <> 0 [flags: flags or EVT_FLAG_CMD_DOWN]
	flags
]

translate-key: func [
	keycode [integer!]
	return: [integer!]
	/local
		key 		[integer!]
		special?	[logic!]
][
	;debug: print ["keycode: " keycode]
	keycode: gdk_keyval_to_upper keycode
	;; DEBUG: print [" translate-key: keycode: " keycode lf]
	special?: no
	key: case [
		all[keycode >= 20h keycode <= 5Ah][keycode]; RED_VK_SPACE to RED_VK_Z 
		all[keycode >= A0h keycode <= FFh][keycode];
		all[keycode >= FFBEh keycode <= FFD5h][special?: yes keycode + RED_VK_F1 - FFBEh]		;RED_VK_F1 to RED_VK_F24
		all[keycode >= FF51h keycode <= FF54h][special?: yes keycode + RED_VK_LEFT - FF51h]		;RED_VK_LEFT to RED_VK_DOWN
		all[keycode >= FF55h keycode <= FF57h][special?: yes keycode + RED_VK_PRIOR - FF51h]	;RED_VK_PRIOR to RED_VK_END
		keycode = FF0Dh	[special?: yes RED_VK_RETURN]
		keycode = FF1Bh [special?: yes RED_VK_ESCAPE]
		keycode = FF50h [special?: yes RED_VK_HOME]
		keycode = FFE5h [special?: yes RED_VK_NUMLOCK]
		keycode = FF08h [special?: yes RED_VK_BACK]
		keycode = FF09h [special?: yes RED_VK_TAB]
		;@@ To complete!
		true [RED_VK_UNKNOWN]
	]
	if special? [key: key or 80000000h]
	;; DEBUG: print [" key: " key " special?=" special?  lf]
	key
]

;; TODO: Copied from macOS and seems to be useful for several windows
; close-pending-windows: func [/local n [integer!] p [int-ptr!]][
; 	n: vector/rs-length? win-array
; 	if zero? n [exit]

; 	p: as int-ptr! vector/rs-head win-array
; 	while [n > 0][
; 		free-handles p/value yes
; 		p: p + 1
; 		n: n - 1
; 	]
; 	vector/rs-clear win-array
; 	close-window?: no
; ]

post-quit-msg: func [
	/local
		e	[integer!]
		tm	[float!]
][
	0
]

;; centralize here connection handlers

respond-event?: func [
	actors		[red-object!]	
	type		[c-string!]
	return:		[logic!]
][
	either null? actors/ctx [
		false
	][
		-1 <> object/rs-find actors as red-value! word/load type
	]
]

respond-mouse-id:	g_quark_from_string "respond-mouse-id"
respond-key-id:		g_quark_from_string "respond-key-id"
respond-window-id:	g_quark_from_string "respond-window-id"

#enum RespondMouseType! [
	ON_LEFT_DOWN:		1
	ON_LEFT_UP:			2
	ON_MIDDLE_DOWN:		4
	ON_MIDDLE_UP:		8
	ON_RIGHT_DOWN:		16	
	ON_RIGHT_UP:		32
	ON_AUX_DOWN:		64
	ON_AUX_UP:			128
	ON_CLICK:			256
	ON_DBL_CLICK:		512
	ON_WHEEL:			1024
	ON_OVER:			2048
]

respond-mouse-add: func [
	widget 		[handle!]
	actors		[red-object!]
	type		[integer!]
	/local
		on-type	[integer!]
][
	on-type: 0
	if respond-event?  actors "on-down" [on-type: on-type or ON_LEFT_DOWN]  
	if respond-event?  actors "on-up" [on-type: on-type or ON_LEFT_UP]
	if respond-event?  actors "on-mid-down" [on-type: on-type or ON_MIDDLE_DOWN] 
	if respond-event?  actors "on-mid-up" [on-type: on-type or ON_MIDDLE_UP]
	if respond-event?  actors "on-alt-down" [on-type: on-type or ON_RIGHT_DOWN] 
	if respond-event?  actors "on-alt-up" [on-type: on-type or ON_RIGHT_UP]
	if respond-event?  actors "on-aux-down" [on-type: on-type or ON_AUX_DOWN] 
	if respond-event?  actors "on-aux-up" [on-type: on-type or ON_AUX_UP]  
	if respond-event?  actors "on-click" [on-type: on-type or ON_CLICK] if respond-event?  actors "on-dbl-click" [on-type: on-type or ON_DBL_CLICK]
	if respond-event?  actors "on-wheel" [on-type: on-type or ON_WHEEL] 
	if respond-event?  actors "on-over" [on-type: on-type or ON_OVER]
	if all[on-type > 1 not null? widget][
		g_object_set_qdata widget respond-mouse-id as int-ptr! on-type
	]
]

respond-mouse?: func [
	widget 	[handle!]
	on-type	[integer!]
	return: [logic!]
][
	(as-integer g_object_get_qdata widget respond-mouse-id) and on-type <> 0
]

#enum RespondWindowType! [
	ON_CLOSE:			1					;-- window events
	ON_MOVE:			2
	ON_SIZE:			4
	ON_MOVING:			8
	ON_SIZING:			16
	ON_TIME:			32
	ON_DRAWING:			64
	ON_SCROLL:			128

	ON_SELECT:			1024
	ON_CHANGE:			2048
	ON_MENU:			4096
]

respond-window-add: func [
	widget 		[handle!]
	actors		[red-object!]
	type		[integer!]
	/local
		on-type	[integer!]
][
	on-type: 0
	if respond-event?  actors "on-close" [on-type: on-type or ON_CLOSE]
	if respond-event?  actors "on-move" [on-type: on-type or ON_MOVE] if respond-event?  actors "on-moving" [on-type: on-type or ON_MOVING]
	if respond-event?  actors "on-size" [on-type: on-type or ON_SIZE] if respond-event?  actors "on-sizing" [on-type: on-type or ON_SIZING]
	if respond-event?  actors "on-time" [on-type: on-type or ON_TIME]  
	if respond-event?  actors "on-drawing" [on-type: on-type or ON_DRAWING]
	if respond-event?  actors "on-scroll" [on-type: on-type or ON_SCROLL] 
	if respond-event?  actors "on-over" [on-type: on-type or ON_OVER]
	if respond-event?  actors "on-select" [on-type: on-type or ON_SELECT]
	if respond-event?  actors "on-change" [on-type: on-type or ON_CHANGE] 
	if respond-event?  actors "on-menu" [on-type: on-type or ON_MENU]
	if all[on-type > 1 not null? widget][
		g_object_set_qdata widget respond-window-id as int-ptr! on-type
	]
]

respond-window?: func [
	widget 	[handle!]
	on-type	[integer!]
	return: [logic!]
][
	(as-integer g_object_get_qdata widget respond-window-id) and on-type  <> 0
]

#enum RespondKeyType! [
	ON_KEY:				1
	ON_KEY_DOWN:		2
	ON_KEY_UP:			4
	ON_IME:				8
	ON_FOCUS:			16
	ON_UNFOCUS:			32
	ON_ENTER:			64
	ON_ZOOM:			128
	ON_PAN:				256
	ON_ROTATE:			512
	ON_TWO_TAP:			1024
	ON_PRESS_TAP:		2048
]

respond-key-add: func [
	widget 		[handle!]
	actors		[red-object!]
	type		[integer!]
	/local
		on-type	[integer!]
][
	on-type: 0
	if respond-event?  actors "on-key" [on-type: on-type or ON_KEY]
	if respond-event?  actors "on-key-down" [on-type: on-type or ON_KEY_DOWN]
	if respond-event?  actors "on-key-up" [on-type: on-type or ON_KEY_UP]
	if respond-event?  actors "on-ime" [on-type: on-type or ON_IME]
	if respond-event?  actors "on-focus" [on-type: on-type or ON_FOCUS]  
	if respond-event?  actors "on-unfocus" [on-type: on-type or ON_UNFOCUS]
	if respond-event?  actors "on-enter" [on-type: on-type or ON_ENTER] 
	if respond-event?  actors "on-zoom" [on-type: on-type or ON_ZOOM]
	if respond-event?  actors "on-pan" [on-type: on-type or ON_PAN]
	if respond-event?  actors "on-rotate" [on-type: on-type or ON_ROTATE] 
	if respond-event?  actors "on-two-tap" [on-type: on-type or ON_TWO_TAP]
	if respond-event?  actors "on-press-tap" [on-type: on-type or ON_PRESS_TAP]
	if all[on-type > 1 not null? widget][
		g_object_set_qdata widget respond-key-id as int-ptr! on-type
	]
]

respond-key?: func [
	widget 	[handle!]
	on-type	[integer!]
	return: [logic!]
][
	(as-integer g_object_get_qdata widget respond-key-id) and on-type <> 0
]

;; The goal is to connect only 
;; TODO:
;; 		*) if useful: create a mask to know what is the connectable
;;		*) if dynamically used in red, create an update-common-event(s) function

connect-common-events: function [
	widget 		[handle!]
	face 		[red-object!]
	type		[integer!]
	; /local
	; 	_widget [handle!]
][
	unless null? widget [
		; _widget: either type = text [
		; 	g_object_get_qdata widget _widget-id
		; ][widget]
		; OR (NOT YET TESTED but if needed for widget with _widget)
		; _widget: g_object_get_qdata widget _widget-id
		; _widget: either null? _widget [widget][_widget]

		;; DEBUG: print [ "ON-DOWN: " get-symbol-name type "->" widget lf]
		if respond-mouse? widget (ON_LEFT_DOWN or ON_RIGHT_DOWN or ON_MIDDLE_DOWN or ON_AUX_DOWN) [gobj_signal_connect(widget "button-press-event" :mouse-button-press-event face/ctx)]
		if respond-mouse? widget ON_OVER [gobj_signal_connect(widget "motion-notify-event" :mouse-motion-notify-event face/ctx)]
			
		;; DEBUG: print [ "ON-UP: " get-symbol-name type "->" widget lf]
		if respond-mouse? widget (ON_LEFT_UP or ON_RIGHT_UP or ON_MIDDLE_UP or ON_AUX_UP) [gobj_signal_connect(widget "button-release-event" :mouse-button-release-event face/ctx)]

		;; DEBUG: print [ "ON-KEY-DOWN: " get-symbol-name type "->" widget lf]
		if respond-key? widget (ON_KEY or ON_KEY_DOWN or ON_FOCUS) [gobj_signal_connect(widget "key-press-event" :key-press-event face/ctx)]
		
		;; DEBUG: print [ "ON-KEY-UP: " get-symbol-name type "->" widget lf]
		if respond-key? widget (ON_KEY_UP or ON_UNFOCUS) [
			gtk_widget_add_events widget GDK_KEY_RELEASE_MASK
			gobj_signal_connect(widget "key-release-event" :key-release-event face/ctx)
		]
	]
]

connect-notify-events: function [
	widget 		[handle!]
	face 		[red-object!]
	sym		[integer!]
	/local
		_widget [handle!]
][
	unless null? widget [
		_widget: either sym = text [
			g_object_get_qdata widget _widget-id
		][widget]
	
			;; DEBUG: print [ "ON-OVER: notify " get-symbol-name type "->" widget lf]

		if respond-mouse? widget EVT_OVER [
			gtk_widget_add_events _widget GDK_ENTER_NOTIFY_MASK or GDK_LEAVE_NOTIFY_MASK
			gobj_signal_connect(_widget "enter-notify-event" :widget-enter-notify-event face/ctx)
			gobj_signal_connect(_widget "leave-notify-event" :widget-leave-notify-event face/ctx)
		]
	]
]

connect-widget-events: function [
	widget 		[handle!]
	face 		[red-object!]
	actors		[red-object!]
	sym		[integer!]
	_widget 	[handle!]
	/local
		buffer	[handle!]
][
	;; register red mouse, key and window on event functions
	respond-mouse-add widget actors sym
	respond-key-add widget actors sym
	respond-window-add widget actors sym

	case [
		sym = check [
			;@@ No click event for check
			;gobj_signal_connect(widget "clicked" :button-clicked null)
			gobj_signal_connect(widget "toggled" :button-toggled face/ctx)
		]
		sym = radio [
			;@@ Line below removed because it generates an error and there is no click event for radio 
			gobj_signal_connect(widget "toggled" :button-toggled face/ctx)
		]
		sym = button [
			if respond-mouse? widget ON_CLICK [gobj_signal_connect(widget "clicked" :button-clicked null)]
		]
		sym = base [
			gobj_signal_connect(widget "draw" :base-draw face/ctx)
			gtk_widget_add_events widget GDK_BUTTON_PRESS_MASK or GDK_BUTTON1_MOTION_MASK or GDK_BUTTON_RELEASE_MASK or GDK_KEY_PRESS_MASK or GDK_KEY_RELEASE_MASK
			gtk_widget_set_can_focus widget no
			gtk_widget_set_focus_on_click widget no
			connect-common-events widget face sym 
		]
		sym = rich-text [
			gobj_signal_connect(widget "draw" :base-draw face/ctx)
			gtk_widget_add_events widget GDK_BUTTON_PRESS_MASK or GDK_BUTTON1_MOTION_MASK or GDK_BUTTON_RELEASE_MASK or GDK_KEY_PRESS_MASK or GDK_KEY_RELEASE_MASK
			gtk_widget_set_can_focus widget yes
			gtk_widget_set_focus_on_click widget yes
			gtk_widget_is_focus widget
			gtk_widget_grab_focus widget
			connect-common-events widget face sym 
		]
		sym = window [
			gobj_signal_connect(widget "delete-event" :window-delete-event null)
			;BUG (make `vid.red` failing):gtk_widget_add_events widget GDK_STRUCTURE_MASK
			;gobj_signal_connect(widget "configure-event" :window-configure-event null)
			gobj_signal_connect(widget "size-allocate" :window-size-allocate null)
		]
		sym = slider [
			gobj_signal_connect(widget "value-changed" :range-value-changed face/ctx)
		]
		sym = text [
			if respond-mouse? widget (ON_LEFT_DOWN or ON_RIGHT_DOWN or ON_MIDDLE_DOWN or ON_AUX_DOWN) [gobj_signal_connect(_widget "button-press-event" :simple-button-press-event widget)]
			if respond-mouse? widget (ON_LEFT_UP or ON_RIGHT_UP or ON_MIDDLE_UP or ON_AUX_UP) [gobj_signal_connect(_widget "button-release-event" :simple-button-release-event widget)]
		]
		sym = field [
			if respond-key? widget (ON_KEY_UP or ON_UNFOCUS) [
				gobj_signal_connect(widget "key-release-event" :field-key-release-event face/ctx)
			]
			;Do not work: gobj_signal_connect(widget "key-press-event" :field-key-press-event face/ctx)
			if respond-mouse? widget (ON_LEFT_UP or ON_RIGHT_UP or ON_MIDDLE_UP or ON_AUX_UP) [gobj_signal_connect(widget "button-release-event" :field-button-release-event face/ctx)]
			
			gtk_widget_set_can_focus widget yes
			gtk_widget_is_focus widget
			;This depends on version >= 3.2
			;gtk_widget_set_focus_on_click widget yes
			gobj_signal_connect(widget "move-focus" :field-move-focus face/ctx)
		]
		sym = progress [
			0
		]
		sym = area [
			; _widget is here buffer
			buffer: gtk_text_view_get_buffer widget
			gobj_signal_connect(buffer "changed" :area-changed widget)
			g_object_set [widget "populate-all" yes null] 
			if respond-mouse? widget (ON_LEFT_DOWN or ON_RIGHT_DOWN or ON_MIDDLE_DOWN or ON_AUX_DOWN) [gobj_signal_connect(widget "button-press-event" :area-button-press-event face/ctx)]
			if respond-mouse? widget (ON_LEFT_UP or ON_RIGHT_UP or ON_MIDDLE_UP or ON_AUX_UP) [gobj_signal_connect(widget "button-release-event" :area-button-release-event face/ctx)]
			if respond-key? widget (ON_KEY or ON_KEY_DOWN or ON_FOCUS) [gobj_signal_connect(widget "key-press-event" :key-press-event face/ctx)]
			if respond-key? widget (ON_KEY_UP or ON_UNFOCUS) [gobj_signal_connect(widget "key-release-event" :key-release-event face/ctx)]
			gobj_signal_connect(widget "populate-popup" :area-populate-popup face/ctx)
		]
		sym = group-box [
			0
		]
		sym = panel [
			gobj_signal_connect(widget "draw" :base-draw face/ctx)
			gtk_widget_set_focus_on_click widget yes
			gtk_widget_add_events widget GDK_BUTTON_PRESS_MASK or GDK_BUTTON1_MOTION_MASK or GDK_BUTTON_RELEASE_MASK or GDK_KEY_PRESS_MASK or GDK_KEY_RELEASE_MASK or GDK_FOCUS_CHANGE_MASK
			;; value: gtk_widget_get_events widget
			;; DEBUG: print ["panel had focus: " gtk_widget_get_focus_on_click widget  lf "get events: " value  " GDK_BUTTON_PRESS_MASK? " GDK_BUTTON_PRESS_MASK and value lf]
			if respond-mouse? widget (ON_LEFT_DOWN or ON_RIGHT_DOWN or ON_MIDDLE_DOWN or ON_AUX_DOWN) [gobj_signal_connect(widget "button-press-event" :mouse-button-press-event face/ctx)]
			if respond-mouse? widget ON_OVER [gobj_signal_connect(widget "motion-notify-event" :mouse-motion-notify-event face/ctx)] 
			
			if respond-mouse? widget (ON_LEFT_UP or ON_RIGHT_UP or ON_MIDDLE_UP or ON_AUX_UP) [gobj_signal_connect(widget "button-release-event" :mouse-button-release-event face/ctx)]
			if respond-key? widget (ON_KEY or ON_KEY_DOWN) [gobj_signal_connect(widget "key-press-event" :key-press-event face/ctx)]
			if respond-key? widget ON_KEY_UP [gobj_signal_connect(widget "key-release-event" :key-release-event face/ctx)]
		]
		sym = tab-panel [
			if respond-window? widget (ON_SELECT or ON_CHANGE) [gobj_signal_connect(widget "switch-page" :tab-panel-switch-page face/ctx)]
		]
		sym = text-list [
			if respond-window? widget (ON_SELECT or ON_CHANGE) [gobj_signal_connect(widget "selected-rows-changed" :text-list-selected-rows-changed face/ctx)]
			connect-common-events widget face sym 
		]
		any [
			sym = drop-list
			sym = drop-down
		][
			if respond-window? widget (ON_SELECT or ON_CHANGE) [gobj_signal_connect(widget "changed" :combo-selection-changed face/ctx)]
		]
		true [0]
	]
	connect-notify-events widget face sym
]