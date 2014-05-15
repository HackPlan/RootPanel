all: install

install:
	npm install

build: install
	node node_modules/coffee-script/bin/coffee -c .

test: build
	bash run-test.bash

clean:
	find . -path './node_modules' -prune -o -name '*.js' -exec rm -fr {} \;

run:
	node node_modules/coffee-script/bin/coffee app.coffee

start: install
	node node_modules/pm2/bin/pm2 -n RootPanel start app.coffee

restart:
	node node_modules/pm2/bin/pm2 restart RootPanel

stop:
	node node_modules/pm2/bin/pm2 delete RootPanel
