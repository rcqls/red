Red/System [
	Title:	"Gtreamer management (camera)"
	Author: "RCqls"
	File: 	%gstreamer.reds
	Tabs: 	4
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#either all [legacy find legacy 'no-camera] [
	init-gst: does [
		0
	]

	make-camera: func [
		data	[red-block!]
		return: [handle!]
	][
		gtk_label_new "Camera not implemented!"
	]

	select-camera: func [
		camera		[handle!]
		idx			[integer!]
	][
		0
	]

	toggle-preview: func [
		camera		[handle!]
		enabled?	[logic!]
	][
		0
	]

][
	red-gst-camera?: 0

	red-camera?: func [
		return: 	[logic!]
		/local 
			env strarr str
			found 	[logic!]
	][
		if 0 = red-gst-camera? [  
			env: system/env-vars 
			found: no
			until [ 
				strarr: g_strsplit env/item "=" 2
				str: as c-string! (strarr/1)
				if 0 = g_strcmp0 str "RED_GTK_CAMERA" [
					str: as c-string! (strarr/2)
					red-gst-camera?: either 0 = g_strcmp0 str "YES" [1][-1]
					found: yes
				]
				env: env + 1
				g_strfreev strarr
				any[found env/item = null]
			]	
		]
		1 = red-gst-camera?
	]

	#define LIBGST-file		"libgstreamer-1.0.so.0"
	#define LIBGUDEV-file 	"libgudev-1.0.so.0"

	#define gst_bus_add_watch(instance handler data) [
		_gst_bus_add_watch instance as-integer handler data
	]

	#define gst_bus_set_sync_handler(bus handler data notify) [
		_gst_bus_set_sync_handler bus as-integer handler data notify
	]

	GstMessage!: alias struct! [
		type 		[integer!]
		timestamp1	[integer!]
		timestamp2	[integer!]
		src 		[handle!]
		;; etc....
	]

	GstMapInfo!: alias struct! [
		memory		[int-ptr!]
		flags			[integer!]
		data			[byte-ptr!]
		size			[integer!]
		maxsize		[integer!]
	] 

	#enum GstMapFlags! [
		GST_MAP_READ
		GST_MAP_WRITE
		GST_MAP_FLAG_LAST
	]

	#enum GstBusSyncReply! [
		GST_BUS_DROP: 0
		GST_BUS_PASS
		GST_BUS_ASYNC
	]

	#enum GstStateChangeReturn! [
		GST_STATE_CHANGE_FAILURE
		GST_STATE_CHANGE_SUCCESS
		GST_STATE_CHANGE_ASYNC
		GST_STATE_CHANGE_NO_PREROLL
	]

	#enum GstState! [
		GST_STATE_VOID_PENDING
		GST_STATE_NULL
		GST_STATE_READY
		GST_STATE_PAUSED
		GST_STATE_PLAYING
	]

	#enum GstMessageType [
		GST_MESSAGE_UNKNOWN: 			0
		GST_MESSAGE_EOS:				1
		GST_MESSAGE_ERROR:				2
		GST_MESSAGE_WARNING:			4
		GST_MESSAGE_INFO:				8
		GST_MESSAGE_TAG:				16
		GST_MESSAGE_BUFFERING:			32
		GST_MESSAGE_STATE_CHANGED:		64
		GST_MESSAGE_STATE_DIRTY:		128
		GST_MESSAGE_STEP_DONE:			256
		GST_MESSAGE_CLOCK_PROVIDE:		512
		GST_MESSAGE_CLOCK_LOST: 		1024
		GST_MESSAGE_NEW_CLOCK:			2048
		GST_MESSAGE_STRUCTURE_CHANGE:	4096
		GST_MESSAGE_STREAM_STATUS:		8192
		GST_MESSAGE_APPLICATION:		16384
		GST_MESSAGE_ELEMENT:			32768
		GST_MESSAGE_SEGMENT_START:		65536
		GST_MESSAGE_SEGMENT_DONE:		131072
		GST_MESSAGE_DURATION_CHANGED:	262144
		GST_MESSAGE_LATENCY:			524288
		GST_MESSAGE_ASYNC_START:		1048576
		GST_MESSAGE_ASYNC_DONE:			2097152
		GST_MESSAGE_REQUEST_STATE:		4194304
		GST_MESSAGE_STEP_START:			8388608
		GST_MESSAGE_QOS:				16777216
		GST_MESSAGE_PROGRESS:			33554432
		GST_MESSAGE_TOC:				67108864
		GST_MESSAGE_RESET_TIME:			134217728
		GST_MESSAGE_STREAM_START:		268435456
		GST_MESSAGE_NEED_CONTEXT:		536870912
		GST_MESSAGE_HAVE_CONTEXT:		1073741824
		;GST_MESSAGE_EXTENDED:			2147483648 ; From here one by one
		;GST_MESSAGE_DEVICE_ADDED: 		2147483649
		;GST_MESSAGE_DEVICE_REMOVED: 	2147483650
		;GST_MESSAGE_PROPERTY_NOTIFY: 	2147483651
		;GST_MESSAGE_STREAM_COLLECTION:	2147483652
		;GST_MESSAGE_STREAMS_SELECTED:	2147483653
		;GST_MESSAGE_REDIRECT:			2147483654
		;GST_MESSAGE_DEVICE_CHANGED: 	2147483655
		;GST_MESSAGE_ANY:				4294967295 ; FFFFFFFFh
	]

	subsystems!: alias struct! [buffer [c-string!] buffer2 [c-string!]]
	video4linux-subsystem: declare subsystems!
	video4linux-subsystem/buffer: "videolinux"
	video4linux-subsystem/buffer: null

	#import [
		LIBGUDEV-file cdecl [
			g_udev_client_new: "g_udev_client_new" [
				subsystems 	[subsystems!]
				return: 	[handle!]
			]
			g_udev_client_query_by_subsystem: "g_udev_client_query_by_subsystem" [
				udevcli 	[handle!]
				subsystem 	[c-string!]
				return: 	[GList!]
			]
			g_udev_device_get_device_file: "g_udev_device_get_device_file" [
				udevice 	[handle!]
				return: 	[c-string!]
			]
			g_udev_device_get_property: "g_udev_device_get_property" [
				udevice 	[handle!]
				prop 		[c-string!]
				return: 	[c-string!]
			]
		]
		LIBGST-file cdecl [
			gst_init: "gst_init" [
				argc 		[int-ptr!]
				argv		[int-ptr!]
			]

			gst_deinit: "gst_deinit" []

			gst_object_unref: "gst_object_unref" [
				bus 		[handle!]
			]

			gst_parse_launch: "gst_parse_launch" [
				cmd 		[c-string!]
				err			[int-ptr!]
				return: 	[handle!]
			]

			gst_pipeline_get_bus: "gst_pipeline_get_bus" [
				pipeline 	[handle!]
				return:		[handle!]
			]

			gst_pipeline_new: "gst_pipeline_new" [
				name		[c-string!]
				return: 	[handle!]
			]
			gst_bin_add_many: "gst_bin_add_many" [
				[variadic]
			]

			gst_bin_add: "gst_bin_add" [
				bin			[handle!]
				element		[handle!]
				return: 	[logic!]
			]

			gst_bus_add_signal_watch: "gst_bus_add_signal_watch" [
				bus 		[handle!]
			]

			_gst_bus_add_watch: "gst_bus_add_watch" [
				bus 		[handle!]
				handler 	[integer!]
				data 		[int-ptr!]
			]

			_gst_bus_set_sync_handler: "gst_bus_set_sync_handler" [
				bus 		[handle!]
				handler 	[integer!]
				data 		[int-ptr!]
				notify 		[integer!]
			]

			gst_bus_enable_sync_message_emission: "gst_bus_enable_sync_message_emission" [
				bus 		[handle!]
			]
			gst_element_factory_make: "gst_element_factory_make" [
				fname		[c-string!]
				name		[c-string!]
				return:		[handle!]
			]
			gst_element_link: "gst_element_link" [
				src 		[handle!]
				dst 		[handle!]
				return: 	[logic!]
			]
			gst_element_set_state: "gst_element_set_state" [
				element		[handle!]
				state 		[integer!]
				return:		[integer!]
			]
			gst_element_get_state: "gst_element_get_state" [
				element		[handle!]
				state 		[int-ptr!]
				pending 	[int-ptr!]
				timeout 	[integer!]
				return:		[integer!]
			]

			gst_message_unref: "gst_message_unref" [
				message 		[handle!]
			]

			gst_message_get_structure: "gst_message_get_structure" [
				message 	[handle!]
				return: 	[handle!]
			]
			gst_structure_has_name: "gst_structure_has_name" [
				struct  	[handle!]
				name 	 	[c-string!]
				return:		[logic!]
			]
			gst_structure_get_name: "gst_structure_get_name" [
				struct  	[handle!]
				return: 	[c-string!]
			]

			gst_structure_get_int: "gst_structure_get_int" [
				struct 		[handle!]
				field 		[c-string!]
				val 		[int-ptr!]
				return: 	[logic!]
			]
			
			gst_message_parse_error: "gst_message_parse_error" [

			]
			gst_sample_get_caps: "gst_sample_get_caps" [
				sample 		[handle!]
				return: 	[handle!]
			]
			gst_sample_get_buffer: "gst_sample_get_buffer" [
				sample 		[handle!]
				return: 	[handle!]
			]
			gst_buffer_map: "gst_buffer_map" [
				buffer 		[handle!]
				info 		[GstMapInfo!]
				flags 		[GstMapFlags!]
				return:		[logic!]
			]
			gst_buffer_unmap: "gst_buffer_unmap" [
				buffer 		[handle!]
				info 		[GstMapInfo!]
			]
			gst_caps_get_structure: "gst_caps_get_structure" [
				caps 		[handle!]
				index 		[integer!]
				return: 	[handle!]
			]
		]
	]

	cameras?: func [
		/local
			udev-cli 	[handle!]
			udevices 	[GList!]
			l 			[GList!]
			udevice 	[handle!]
	][
		udev-cli: g_udev_client_new video4linux-subsystem

		udevices: g_udev_client_query_by_subsystem udev-cli "video4linux"
		l: udevices
		while [not null? l][
			;; DEBUG: print ["hide-invisible: " child/data lf]
			udevice: l/data
			print [g_udev_device_get_device_file udevice 
			" " g_udev_device_get_property udevice "ID_V4L_PRODUCT"
			lf]
			g_object_unref udevice
			l: l/next
		]
		g_list_free as handle! udevices
		g_clear_object as-integer udev-cli
	]

	init-gst: does [
		if red-camera? [
			gst_init null null
			print ["Experimental camera initialized!" lf]
		]
	]

	red-gst-pipeline: 		g_quark_from_string "red-gst-pipeline"

	on-camera-message: func [
		[cdecl]
		bus       [handle!]
		message   [GstMessage!]
		data      [int-ptr!]
		return:   [logic!]
	][
		case [
			message/type =  GST_MESSAGE_ERROR [
			print ["Camera error!" lf]
			;puts message.parse_error[0].message
			;;gtk_main_quit
			yes
			]
			message/type =  GST_MESSAGE_EOS [
			print ["Camera done!" lf]
			;;gtk_main_quit
			yes
			]
			true [no]
		]
	]

	make-camera: func [
		data	[red-block!]
		return: [handle!]
		/local
			pipeline 	[handle!]
			src 		[handle!]
			conv 		[handle!]
			snk 		[handle!]
			bus 		[handle!]
			widget 		[integer!]
			n 			[integer!]
			cnt			[integer!]
			str			[red-string!]
			name 		[c-string!]
			size 		[integer!]
	][
		either red-camera? [
			pipeline: gst_pipeline_new "pipeline"

			src: gst_element_factory_make "v4l2src" "source"
			if null? src [ print ["v4l2src is not activated (maybe GST_V4L2_USE_LIBV4L2=1 is needed)" lf]]
			conv: gst_element_factory_make "videoconvert" "convert"
			if null? conv [print ["conv issue" lf]]
			snk: gst_element_factory_make "gtksink" "display"
			if null? snk [print ["snk issue" lf]]
			gst_bin_add_many [pipeline src conv snk null]

			bus: gst_pipeline_get_bus pipeline
			gst_bus_add_watch( bus :on-camera-message null)

			gst_element_link src conv
			gst_element_link conv snk

			widget: 0
			g_object_get [snk "widget" :widget null]

			;-- get all devices name TODO
			cnt: 1
			if zero? cnt [return null]

			if TYPE_OF(data) <> TYPE_BLOCK [
				block/make-at data cnt
			]
			n: 0
			while [n < cnt] [
				name: "/dev/video0"
				size: length? name
				str: string/make-at ALLOC_TAIL(data) size Latin1
				unicode/load-utf8-stream name size str null
				n: n + 1
			]
			g_object_set_qdata as handle! widget red-gst-pipeline pipeline
			;; return widget
			as handle! widget
		][
			gtk_label_new "Camera not activated!"
		]
	]

	select-camera: func [
		camera		[handle!]
		idx			[integer!]
		/local
			pipeline	[handle!]

	][
		if red-camera? [
			pipeline: g_object_get_qdata camera red-gst-pipeline
			gst_element_set_state pipeline GST_STATE_READY
		]
	]

	toggle-preview: func [
		camera		[handle!]
		enabled?	[logic!]
		/local
			pipeline	[handle!]
	][
		if red-camera? [
			pipeline: g_object_get_qdata camera red-gst-pipeline
			either enabled? [
				gst_element_set_state pipeline GST_STATE_PLAYING
			][
				gst_element_set_state pipeline GST_STATE_READY
			]
		]
	]

	; still-image-handler: func [
	; 	[cdecl]
	; 	block	[int-ptr!]
	; 	buffer	[integer!]
	; 	error	[integer!]
	; 	/local
	; 		values	[red-value!]
	; 		data	[integer!]
	; ][
	; 	if error <> 0 [exit]		;-- error occur

	; 	values: as red-value! block/6
	; 	data: objc_msgSend [
	; 		objc_getClass "AVCaptureStillImageOutput"
	; 		sel_getUid "jpegStillImageNSDataRepresentation:"
	; 		buffer
	; 	]
	; 	image/init-image
	; 		as red-image! values + FACE_OBJ_IMAGE
	; 		OS-image/load-nsdata as int-ptr! data
	; ]

	; snap-camera: func [				;-- capture an image of current preview window
	; 	camera		[integer!]
	; 	/local
	; 		blk			[block_literal!]
	; 		isa			[integer!]
	; 		image		[integer!]
	; 		connection	[integer!]
	; 		layer		[integer!]
	; 		orientation [integer!]
	; 		sel			[integer!]
	; ][
	; 	blk: declare block_literal!
	; 	isa: objc_getAssociatedObject camera RedCameraSessionKey
	; 	if zero? objc_msgSend [isa sel_getUid "isRunning"][exit]

	; 	objc_block_descriptor/reserved: 0
	; 	objc_block_descriptor/size: 4 * 6

	; 	blk/isa: _NSConcreteStackBlock
	; 	blk/flags: 1 << 29				;-- BLOCK_HAS_DESCRIPTOR, no copy and dispose helpers
	; 	blk/reserved: 0
	; 	blk/invoke: as int-ptr! :still-image-handler
	; 	blk/descriptor: as int-ptr! objc_block_descriptor
	; 	blk/value: as int-ptr! get-face-values camera
	; 	image: objc_getAssociatedObject camera RedCameraImageKey
	; 	connection: objc_msgSend [image sel_getUid "connectionWithMediaType:" AVMediaTypeVideo]

	; 	;-- Update the orientation on the still image output video connection before capturing
	; 	;layer: objc_msgSend [camera sel_getUid "layer"]
	; 	;orientation: objc_msgSend [layer sel_getUid "connection"]
	; 	;orientation: objc_msgSend [orientation sel_getUid "videoOrientation"]
	; 	;objc_msgSend [connection sel_getUid "setVideoOrientation:" orientation]

	; 	objc_msgSend [
	; 		image
	; 		sel_getUid "captureStillImageAsynchronouslyFromConnection:completionHandler:"
	; 		connection
	; 		blk
	; 	]
	; 	sel: sel_getUid "isCapturingStillImage"
	; 	until [zero? objc_msgSend [image sel]]
	; ]

]