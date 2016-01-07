
upload-all:
	../nodemcu-uploader/nodemcu-uploader.py --port /dev/tty.SLAB_USBtoUART upload \
	blinkm.lua rgbtube.lua main.lua init.lua http_req.lua http_sendfile.lua -c
	../nodemcu-uploader/nodemcu-uploader.py --port /dev/tty.SLAB_USBtoUART upload \
	static/index.html:static-index.html \
	static/zepto-touch.js.gz:static-zepto-touch.js.gz \

