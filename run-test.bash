#!/bin/bash

node node_modules/coffee-script/bin/coffee app.coffee &
SERVER_PID="$!"
sleep 1s
node node_modules/coffee-script/bin/coffee TEST/API/init.coffee
node node_modules/jasmine-node/bin/jasmine-node --junitreport TEST/API
kill "$SERVER_PID"
