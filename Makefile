all: install

install:
	npm install

clean_socket:
	-rm ../rootpanel.sock

run: clean_socket
	node start.js

start: clean_socket
	node node_modules/forever/bin/forever start start.js

restart: clean_socket
	node node_modules/forever/bin/forever restart start.js

stop:
	node node_modules/forever/bin/forever stop start.js
