#!/usr/bin/env coffee

Root = require './core'

global.root = new Root Root.loadConfig()
root.start()
