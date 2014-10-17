bundle: bundle/window.html bundle/window.js bundle/chrome.app.background.js

bundle/window.html: window.html window.css graphics/*.svg
	cat window.html > bundle/window.html
	echo "<style>" >> bundle/window.html
	cat window.css >> bundle/window.html
	echo "</style>" >> bundle/window.html
	make $(subst .svg,.html,$(wildcard graphics/*.svg))
	cat graphics/*.html >> bundle/window.html

bundle/window.js: window.coffee
	coffee --print --compile window.coffee > window.js
	browserify window.js > bundle/window.js
	rm -f window.js

bundle/chrome.app.background.js: chrome.app.background.coffee
	coffee --print --compile chrome.app.background.coffee > bundle/chrome.app.background.js

graphics/%.html: graphics/%.svg
	cat '$<' \
		| sed 's/<?xml version="1.0" encoding="UTF-8" standalone="no"?>//' \
		| sed 's/<svg /<svg id="$(basename $(@F)) icon" /' \
		| sed 's/<!-- Generator: Sketch 3.1 (8751) - http:\/\/www.bohemiancoding.com\/sketch -->//' \
		| sed 's/ sketch:type="MSPage"//' \
		| sed 's/ sketch:type="MSArtboardGroup"//' \
		| sed 's/ sketch:type="MSShapeGroup"//' \
		| sed 's/<desc>Created with Sketch.<\/desc>//' \
		| sed 's/ id="radialGradient/ preserve-id="radialGradient/' \
		| sed 's/ id=/ class=/' \
		| sed 's/ preserve-id=/ id=/' \
		| sed 's/radialGradient-/$(basename $(@F))-radialGradient-/' \
		| grep '<' \
		> '$@'

clean:
	rm -f graphics/*.html
	rm -f bundle/window.html
	rm -f bundle/window.js
	rm -f bundle/chrome.app.background.js

pow:
	mkdir -p ~/.pow/noir
	ln -s $(PWD)/bundle ~/.pow/noir/public

unlink_pow:
	rm -rf ~/.pow/noir
