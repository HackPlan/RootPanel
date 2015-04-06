#!/usr/bin/env coffee

Root = require './core'

Root.findConfig(__dirname).done (config) ->
  global.root = new Root config
