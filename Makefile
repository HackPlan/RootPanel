all: test

install:
	npm install

test: build
	node node_modules/coffee-script/bin/coffee app.coffee &
	SERVER_PID="$!"
	sleep 1s
	node node_modules/coffee-script/bin/coffee TEST/API/init.coffee
	node node_modules/jasmine-node/bin/jasmine-node --junitreport TEST/API
	kill "$SERVER_PID"

build:
	node node_modules/coffee-script/bin/coffee -c .

clean:
	find . -path './node_modules' -prune -o -name '*.js' -exec rm -fr {} \;

run:
	node node_modules/coffee-script/bin/coffee app.coffee

start:
	node node_modules/pm2/bin/pm2 -n RootPanel start app.coffee

restart:
	node node_modules/pm2/bin/pm2 restart RootPanel

stop:
	node node_modules/pm2/bin/pm2 delete RootPanel
