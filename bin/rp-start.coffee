#!/usr/bin/env coffee

child_process = require 'child_process'

child_process.exec "make start", {cwd: "#{__dirname}/../"}, (err) ->
  throw err if err
  process.exit()
