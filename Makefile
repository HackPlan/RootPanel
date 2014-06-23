all: install

install:
	npm install

build: install
	node node_modules/coffee-script/bin/coffee -c .

clean:
	find . -path './node_modules' -prune -o -name '*.js' -exec rm -fr {} \;

run:
	rm ../rootpanel.sock
	node node_modules/coffee-script/bin/coffee app.coffee

start: build
	rm ../rootpanel.sock
	node node_modules/forever/bin/forever start app.js

restart:
	rm ../rootpanel.sock
	node node_modules/forever/bin/forever restart app.js

stop:
	node node_modules/forever/bin/forever stop app.js
