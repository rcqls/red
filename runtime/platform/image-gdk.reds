Red/System [
	Title:   "Image routine functions using gdk"
	Author:  "Qingtian Xie, RCqls"
	File: 	 %image-gdk.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define IMG_NODE_HAS_BUFFER		1
#define IMG_NODE_MODIFIED		2


argb-to-rgba: func [
	color		[integer!]
	return: 	[integer!]
	/local
		r			[integer!]
		b			[integer!]
		g			[integer!]
		a			[integer!]
][
	a: (color >>> 24 and FFh) 
	r: (color >> 16 and FFh) 
	g: (color >> 8 and FFh) 
	b: (color  and FFh)
	color: (r << 24 and FF000000h) or (g << 16  and 00FF0000h) or ( b << 8 and FF00h) or ( a and FFh)
	color
]

argb-to-abgr: func [
	color		[integer!]
	return: 	[integer!]
	/local
		r			[integer!]
		b			[integer!]
		g			[integer!]
		a			[integer!]
][
	a: (color >>> 24 and FFh) 
	r: (color >> 16 and FFh) 
	g: (color >> 8 and FFh) 
	b: (color  and FFh)
	color: (a << 24 and FF000000h) or (b << 16  and 00FF0000h) or ( g << 8 and FF00h) or ( r and FFh)
	color
]

OS-image: context [

	img-node!: alias struct! [
		flags	[integer!]	;-- bit 0: if set, has buffer | bit 1: if set, buffer has been modified
		handle	[int-ptr!]
		buffer	[int-ptr!]
		size	[integer!]
	]

	#either OS = 'Windows [
		#define LIBGDK-file		"libgtk-3-0.dll" ;or libgdk-3-0.dll
	][
		#define LIBGDK-file		"libgtk-3.so.0" ;or libgdk-3.so.0
	]

	#import [
		LIBGDK-file cdecl [
			gdk_pixbuf_new: "gdk_pixbuf_new" [
				colorsp 	[integer!]
				alpha 		[logic!]
				bits 		[integer!]
				width 		[integer!]
				height 		[integer!]
				return: 	[handle!]
			]
			gdk_pixbuf_new_from_bytes: "gdk_pixbuf_new_from_bytes" [
				data 		[handle!]
				colorsp 	[integer!]
				alpha 		[logic!]
				bits 		[integer!]
				width 		[integer!]
				height 		[integer!]
				rowstride	[integer!]
				return: 	[handle!]
			]
			gdk_pixbuf_new_from_file: "gdk_pixbuf_new_from_file" [
				name		[c-string!]
				err 		[handle!]
				return: 	[handle!]
			]
			gdk_pixbuf_copy: "gdk_pixbuf_copy" [
				pixbuf 		[handle!]
				return: 	[handle!]
			]
			gdk_pixbuf_get_byte_length: "gdk_pixbuf_get_byte_length" [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_width: "gdk_pixbuf_get_width" [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_height: "gdk_pixbuf_get_height" [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_pixels: "gdk_pixbuf_get_pixels" [
				pixbuf 		[handle!]
				return: 	[byte-ptr!]
			]
			gdk_pixbuf_get_rowstride: "gdk_pixbuf_get_rowstride"  [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_n_channels: "gdk_pixbuf_get_n_channels" [
				pixbuf 		[handle!]
				return: 	[integer!]
			]
			gdk_pixbuf_get_has_alpha: "gdk_pixbuf_get_has_alpha" [
				pixbuf 		[handle!]
				return:		[logic!]
			]
			gdk_pixbuf_loader_new: "gdk_pixbuf_loader_new" [
				return: 	[handle!]
			]
			gdk_pixbuf_loader_get_pixbuf: "gdk_pixbuf_loader_get_pixbuf" [
				loader		[handle!]
				return: 	[handle!]
			]
			gdk_pixbuf_loader_write: "gdk_pixbuf_loader_write" [
				loader		[handle!]
				data 		[handle!]
				size 		[integer!]
				err 		[handle!]
				return: 	[logic!]
			]
			gdk_pixbuf_loader_close: "gdk_pixbuf_loader_close" [
				loader		[handle!]
				err 		[handle!]
				return: 	[logic!]
			]
			g_object_unref: "g_object_unref" [
				obj 	[handle!]
			]
		]
	]

	width?: func [
		handle		[node!]
		return:		[integer!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (as series! handle/value) + 1
		IMAGE_WIDTH(inode/size)
	]

	height?: func [
		handle		[node!]
		return:		[integer!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (as series! handle/value) + 1
		IMAGE_HEIGHT(inode/size)
	]

	#enum post-transf! [POST-TRANSF-NONE POST-ARGB-TO-ABGR POST-ARGB-TO-RGBA]
	
	post-transf?: POST-TRANSF-NONE
	
	post-transf: func [ mode [post-transf!]][post-transf?: mode]
	
	lock-bitmap: func [
		img			[red-image!]
		write?		[logic!]
		return:		[integer!]
		/local
			inode	[img-node!]
	][
		inode: as img-node! (as series! img/node/value) + 1
		if zero? inode/flags [
			;; DEBUG: print ["lock-bitmap: flags" lf]
			inode/flags: IMG_NODE_HAS_BUFFER
			inode/buffer: OS-image/data-to-image inode/handle -1 yes yes
		]
		if write? [inode/flags: inode/flags or IMG_NODE_MODIFIED]
		post-transf POST-TRANSF-NONE ; no post-transf to apply before 
		as integer! inode
	]

	; unlock-bitmap: func [					;-- do nothing on GDK backend
	; 	image		[red-image!]
	; 	bitmap		[integer!]
	; ][
	; ]

	unlock-bitmap: func [					;-- do nothing on GDK backend
		image		[red-image!]
		bitmap		[integer!]
		/local
			w	 	[integer!]
			h	 	[integer!]
			node	[img-node!]
	][
		unless post-transf? = POST-TRANSF-NONE [
			w: IMAGE_WIDTH(image/size)
			h: IMAGE_HEIGHT(image/size)
			node: as img-node! bitmap
			case [
				post-transf? = POST-ARGB-TO-ABGR [buffer-argb-to-abgr node/buffer w h]
				post-transf? = POST-ARGB-TO-RGBA [buffer-argb-to-rgba node/buffer w h]
			]
		]
	]

	

	get-data: func [
		handle		[integer!]
		stride		[int-ptr!]
		return:		[int-ptr!]
		/local
			node			[img-node!]
	][
		;; DEBUG: print ["OS-image/get-data" lf]
		node: as img-node! handle
		stride/value: IMAGE_WIDTH(node/size) * 4
		node/buffer
	]

	get-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		return:		[integer!]
		/local
			node	[img-node!]
			buf		[int-ptr!]
	][
		node: as img-node! (as series! bitmap/value) + 1
		buf: node/buffer + index
		buf/value
	]

	set-pixel: func [
		bitmap		[node!]
		index		[integer!]				;-- zero-based
		color		[integer!]
		return:		[integer!]
		/local
			node	[img-node!]
			buf		[int-ptr!]
	][
		node: as img-node! (as series! bitmap/value) + 1
		node/flags: node/flags or IMG_NODE_MODIFIED
		buf: node/buffer + index
		buf/value: color
		color
	]

	delete: func [img [red-image!]][
		; GdipDisposeImage as-integer img/node
		0
	]

	; copied from quartz but do not think it is finished
	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [integer!]
		/local
			graphic [integer!]
			old-w	[integer!]
			old-h	[integer!]
			format	[integer!]
			bitmap	[integer!]
	][
		old-w: IMAGE_WIDTH(img/size)
		old-h: IMAGE_HEIGHT(img/size)

		graphic: 0
		format: 0
		bitmap: 0
		as-integer img/node
	]

	; UNUSED in Quartz ???? Maybe for a future use???? 
	copy: func [
		dst		[integer!]
		src		[integer!]
		bytes	[integer!]
		offset	[integer!]
		/local
			dst-buf [byte-ptr!]
			src-buf [byte-ptr!]
	][
		; dst-buf: CGBitmapContextGetData dst
		; src-buf: CGBitmapContextGetData src
		; copy-memory dst-buf src-buf + offset bytes
	]

	make-node: func [
		handle	[int-ptr!]
		buffer	[int-ptr!]
		flags	[integer!]
		width	[integer!]
		height	[integer!]
		return: [node!]
		/local
			node	[node!]
			inode	[img-node!]
	][
		node: alloc-cells 1					;-- 16 bytes
		inode: as img-node! (as series! node/value) + 1
		inode/flags: flags
		inode/handle: handle
		inode/buffer: buffer
		inode/size: height << 16 or width
		node
	]

	alpha-channel?: func [
		pixbuf	[integer!]
		return:	[logic!]
	][
		gdk_pixbuf_get_has_alpha as handle! pixbuf
	]

	buffer-rgba-to-argb: func [
		buf 	[int-ptr!]
		width	[integer!]
		height	[integer!]
		return: [int-ptr!]	; not necessary since buf is already a pointer
		/local
			data-pixbuf 	[int-ptr!]
			end-data-pixbuf	[int-ptr!]
			pixel			[integer!]
			i 				[integer!]
	][
		data-pixbuf:  buf
		end-data-pixbuf: data-pixbuf + (width * height)
		;; DEBUG: print ["buffer-rgba-to-argb -> size: " width "x" height lf]
		while [data-pixbuf < end-data-pixbuf][
			pixel: data-pixbuf/value
			;; DEBUG: print ["pixel:" pixel lf]
			pixel: (pixel >> 8) or (255 - (pixel << 24)) ; RGBA -> ARGB
			data-pixbuf/value: pixel
			data-pixbuf: data-pixbuf + 1
		]
		buf
	]

	buffer-argb-to-abgr: func [
		buf 	[int-ptr!]
		width	[integer!]
		height	[integer!]
		return: [int-ptr!]	; not necessary since buf is already a pointer
		/local
			data-pixbuf 	[int-ptr!]
			end-data-pixbuf	[int-ptr!]
			pixel			[integer!]
			i 				[integer!]
	][
		data-pixbuf:  buf
		end-data-pixbuf: data-pixbuf + (width * height)
		;; DEBUG: print ["buffer-argb -> size: " width "x" height lf]
		while [data-pixbuf < end-data-pixbuf][
			pixel: data-pixbuf/value
			;; DEBUG: print ["pixel:" pixel lf]
			pixel: argb-to-abgr pixel
			data-pixbuf/value: pixel
			data-pixbuf: data-pixbuf + 1
		]
		buf
	]

	buffer-argb-to-rgba: func [
		buf 	[int-ptr!]
		width	[integer!]
		height	[integer!]
		return: [int-ptr!]	; not necessary since buf is already a pointer
		/local
			data-pixbuf 	[int-ptr!]
			end-data-pixbuf	[int-ptr!]
			pixel			[integer!]
			i 				[integer!]
	][
		data-pixbuf:  buf
		end-data-pixbuf: data-pixbuf + (width * height)
		;; DEBUG: print ["buffer-argb -> size: " width "x" height lf]
		while [data-pixbuf < end-data-pixbuf][
			pixel: data-pixbuf/value
			;; DEBUG: print ["pixel:" pixel lf]
			pixel: argb-to-rgba pixel
			data-pixbuf/value: pixel
			data-pixbuf: data-pixbuf + 1
		]
		buf
	]

	; In particular used to query buffer from handle in lock-bitmap
	data-to-image: func [				;-- convert Pixbuf to OS handle or internal buffer
		data		[int-ptr!]
		len 		[integer!] ; @@ added for data length
		image?		[logic!]
		edit?		[logic!]
		return: 	[int-ptr!]
		/local
			; color-space [integer!] ; Only  RGB 
			width		[integer!]
			height		[integer!]
			ctx			[integer!]
			; bytes-row	[integer!]
			image-data	[integer!]
			image		[integer!]
			n			[integer!]
			info		[integer!]
			alpha?		[logic!]
			buf			[byte-ptr!]
			loader 		[handle!]
	][
		either image? [
			image: as-integer data
		][
			loader: gdk_pixbuf_loader_new
			gdk_pixbuf_loader_write loader data len null
			gdk_pixbuf_loader_close loader null
			image: as-integer gdk_pixbuf_loader_get_pixbuf loader
		]

		unless edit? [return as int-ptr! image]

		alpha?: alpha-channel? image
		; color-space:  ONLY RGB
		width: gdk_pixbuf_get_width as handle! image
		height: gdk_pixbuf_get_height as handle! image

		; bytes-row: width * 4

		; maybe better use other copy
		buf: gdk_pixbuf_get_pixels gdk_pixbuf_copy as handle! image
		buffer-rgba-to-argb as int-ptr! buf width height
	]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [node!]
		/local
			h	[int-ptr!]
	][
		;; DEBUG: print ["load-binary" lf]

		h: data-to-image as int-ptr! data len no no
		make-node h null 0 gdk_pixbuf_get_width h gdk_pixbuf_get_height h
	]

	load-pixbuf: func [
		h		[int-ptr!]
		return:	[node!]
	][
		;; DEBUG: print ["load-pixbuf" lf]
		make-node h null 0 gdk_pixbuf_get_width h gdk_pixbuf_get_height h
		;as node! 0
	]

	load-image: func [			;-- load image from external resource: file!
		src			[red-string!]
		return:		[node!]
		/local
			path 	[c-string!]
			pixbuf	[int-ptr!]
			h		[integer!]
			w		[integer!]
			buf 	[byte-ptr!]

	][
		path: file/to-OS-path src ; DOES NOT WORK as in macOS: simple-io/to-NSURL src yes
		;; DEBUG: print [ "load-image: " path lf]
		pixbuf: gdk_pixbuf_new_from_file path null
		;; print ["handle: " pixbuf ", wxh: " gdk_pixbuf_get_width h "x" gdk_pixbuf_get_height h]
		w: gdk_pixbuf_get_width pixbuf h: gdk_pixbuf_get_height pixbuf
		;buf: gdk_pixbuf_get_pixels pixbuf
		;buffer-argb-to-abgr as int-ptr! buf w h
		make-node pixbuf null 0 w h
	]

	; DO NOT KNOW IF USEFUL!
	; make-image: func [
	; 	width	[integer!]
	; 	height	[integer!]
	; 	rgb		[byte-ptr!]
	; 	alpha	[byte-ptr!]
	; 	color	[red-tuple!]
	; 	return: [int-ptr!]
	; 	/local
	; 		a		[integer!]
	; 		r		[integer!]
	; 		b		[integer!]
	; 		g		[integer!]
	; 		pixbuf	[handle!]
	; 		pixels	[byte-ptr!]
	; 		channel [integer!]
	; 		cpt 	[integer!]
	; 		end		[integer!]
	; ][
	; 	;print-line "make-image"
	; 	if any [zero? width zero? height][return null]
	; 	pixbuf: gdk_pixbuf_new 0 yes 8 width height
	; 	if null? pixbuf [
	; 	 	fire [TO_ERROR(script invalid-arg) pair/push width height]
	; 	]
	; 	;print-line "ici"
	; 	pixels: gdk_pixbuf_get_pixels pixbuf
	; 	channel: gdk_pixbuf_get_n_channels pixbuf ; = 4 
	; 	end: width * height

	; 	; @@ TO IMPROVE since I mimicked what was in gdiplus (integer!) but gdk is directly in byte! 
	; 	either null? color [
	; 		cpt: 0
	; 		while [cpt < end][
	; 			either null? alpha [a: 255][a: 255 - as-integer alpha/1 alpha: alpha + 1]
	; 			either null? rgb [r: 255 g: 255 b: 255][
	; 				r: as-integer rgb/1
	; 				g: as-integer rgb/2
	; 				b: as-integer rgb/3
	; 				rgb: rgb + 3
	; 			]
	; 			pixels/1: as byte! (r << 16)
	; 			pixels/2: as byte! (g << 8)
	; 			pixels/3: as byte! b
	; 			pixels/4: as byte! a << 24
	; 			pixels: pixels + channel
	; 			cpt: cpt + 1
	; 		]
	; 	][
	; 		r: color/array1
	; 		a: either TUPLE_SIZE?(color) = 3 [255][255 - (r >>> 24)]
	; 		r: r >> 16 and FFh or (r and FF00h) or (r and FFh << 16) or (a << 24)
	; 		cpt: 0
	; 		while [cpt < end][
	; 			pixels/1: as byte! (r >> 16 and FFh)
	; 			pixels/2: as byte! (r and FF00h)
	; 			pixels/3: as byte! (r and FFh << 16)
	; 			pixels/4: as byte! (a << 24)
	; 			pixels: pixels + channel
	; 			cpt: cpt + 1
	; 		]
	; 	]
	; 	pixbuf
	; ]

	make-image: func [
		width	[integer!]
		height	[integer!]
		rgb		[byte-ptr!]
		alpha	[byte-ptr!]
		color	[red-tuple!]
		return: [node!]
		/local
			a			[integer!]
			r			[integer!]
			b			[integer!]
			g			[integer!]
			x			[integer!]
			y			[integer!]
			scan0		[int-ptr!]
			pos			[integer!]
	][
		;; DEBUG: print ["make-image" lf]
		scan0: as int-ptr! allocate width * height * 4
		y: 0
		either null? color [
			while [y < height][
				x: 0
				while [x < width][
					pos: width * y + x + 1
					either null? alpha [a: 255][a: 255 - as-integer alpha/1 alpha: alpha + 1]
					either null? rgb [r: 255 g: 255 b: 255][
						r: as-integer rgb/1
						g: as-integer rgb/2
						b: as-integer rgb/3
						rgb: rgb + 3
					]
					scan0/pos: r  or (g << 8) or (b << 16) or (a << 24)
					x: x + 1
				]
				y: y + 1
			]
		][
			r: color/array1
			a: either TUPLE_SIZE?(color) = 3 [255][255 - (r  and FFh)]
			r: (r >>> 24 and FFh) or ((r >> 16 and FFh) << 8) or ((r >> 8 and FFh) << 16) or (a << 24)
			while [y < height][
				x: 0
				while [x < width][
					pos: width * y + x + 1
					scan0/pos: r
					x: x + 1
				]
				y: y + 1
			]
		]
		make-node null scan0 IMG_NODE_HAS_BUFFER or IMG_NODE_MODIFIED width height
	]

	make-pixbuf: func [
		image	[red-image!]
		return: [int-ptr!]
		/local
			w	 [integer!]
			h	 [integer!]
			data [int-ptr!]
			end  [int-ptr!]
			clr  [integer!]
			img  [int-ptr!]
			node [img-node!]
	][
		node: as img-node! (as series! image/node/value) + 1
		w: IMAGE_WIDTH(image/size)
		h: IMAGE_HEIGHT(image/size)
		; need to change rgba en argb
		img: gdk_pixbuf_new 0 yes 8 w h;CGImageCreate w h 8 32 w * 4 clr 2004h data null true 0 ;-- kCGRenderingIntentDefault
		copy-memory gdk_pixbuf_get_pixels img as byte-ptr! node/buffer w * h * 4
		;; DEBUG: print ["make-pixbuf " img lf]
		img
	]

	to-pixbuf: func [
		img		[red-image!]
		return: [int-ptr!]
		/local
			inode	[img-node!]
			pixbuf	[int-ptr!]
			width 	[integer!]
			height 	[integer!]
	][
		;; DEBUG: print ["OS-image/to-pixbuf" lf]
		inode: as img-node! (as series! img/node/value) + 1
		if inode/flags and IMG_NODE_MODIFIED <> 0 [
			pixbuf: make-pixbuf img
			unless null? inode/handle [g_object_unref inode/handle]
			inode/handle: pixbuf
			inode/flags: IMG_NODE_HAS_BUFFER
		]
		inode/handle
	]

	to-argb-pixbuf: func [
		image	[red-image!]
		return: [int-ptr!]
		/local
			w	 	[integer!]
			h	 	[integer!]
			bitmap	[integer!]
			data	[int-ptr!]
			stride	[integer!]
			pixbuf	[int-ptr!]
			buf		[byte-ptr!]
	][
		w: IMAGE_WIDTH(image/size)
		h: IMAGE_HEIGHT(image/size)
		stride: 0
		bitmap: OS-image/lock-bitmap image yes
		data: OS-image/get-data bitmap :stride
		pixbuf: gdk_pixbuf_new 0 yes 8 w h
		copy-memory gdk_pixbuf_get_pixels pixbuf as byte-ptr! data w * h * 4
		OS-image/unlock-bitmap image bitmap
		buf: gdk_pixbuf_get_pixels pixbuf
		buffer-argb-to-abgr as int-ptr! buf w h
		pixbuf
	]

	encode: func [
		image	[red-image!]
		slot	[red-value!]
		format	[integer!]
		return: [red-value!]
		/local
			type		[integer!]
			path		[integer!]
			dst			[integer!]
			img			[int-ptr!]
	][
		;; DEBUG: 
		print ["encode" lf]
		switch format [
			IMAGE_BMP  [probe "type: kUTTypeBMP"]
			IMAGE_PNG  [probe "type: kUTTypePNG"]
			IMAGE_GIF  [probe "type: kUTTypeGIF"]
			IMAGE_JPEG [probe "type: kUTTypeJPEG"]
			IMAGE_TIFF [probe "type: kUTTypeTIFF"]
			default    [probe "Cannot find image encoder" return null]
		]

		img: to-pixbuf image
		; switch TYPE_OF(slot) [
		; 	TYPE_URL
		; 	TYPE_FILE [
		; 		path: simple-io/to-NSURL as red-string! slot yes
		; 		dst: CGImageDestinationCreateWithURL path type 1 0
		; 		;if zero? dst []				;-- error
		; 		CGImageDestinationAddImage dst img 0
		; 		unless CGImageDestinationFinalize dst [
		; 			0 ;-- error
		; 		]
		; 		CFRelease path
		; 		CFRelease dst
		; 	]
		; 	default [0]
		; ]
		slot
	]

	clone: func [
		src		[red-image!]
		dst		[red-image!]
		part	[integer!]
		size	[red-pair!]
		part?	[logic!]
		return: [red-image!]
		/local
			x		[integer!]
			y		[integer!]
			w		[integer!]
			h		[integer!]
			offset	[integer!]
			handle	[integer!]
			width	[integer!]
			height	[integer!]
			bmp		[integer!]
			format	[integer!]
	][
		width: IMAGE_WIDTH(src/size)
		height: IMAGE_WIDTH(src/size)
		offset: src/head
		x: offset % width
		y: offset / width
		handle: as-integer src/node
		bmp: 0

		dst/header: TYPE_IMAGE
		dst/head: 0
		dst/node: as node! bmp
		dst
	]

]