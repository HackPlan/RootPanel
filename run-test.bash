#!/bin/bash

node node_modules/coffee-script/bin/coffee app.coffee &
sleep 1s
SERVER_PID="$!"
node node_modules/coffee-script/bin/coffee TEST/API/init.coffee
node node_modules/jasmine-node/bin/jasmine-node --junitreport TEST/API
kill "$SERVER_PID"
