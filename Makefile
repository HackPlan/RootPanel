all: install

install:
	npm install

run:
	node start.js

start:
	node node_modules/forever/bin/forever start start.js

restart:
	node node_modules/forever/bin/forever restart start.js

stop:
	node node_modules/forever/bin/forever stop start.js
