process.env.NODE_ENV = 'test'

Root = require '../core'

global.config = require '../sample/core.config.coffee'
global.root = new Root config

root.start()

require './snippet'
