process.env.NODE_ENV = 'test'

_ = require 'lodash'

Root = require '../core'
snippet = require './snippet'

global.config = require '../sample/core.config.coffee'
global.root = new Root config

root.start()

_.extend global, snippet

chai.should()
chai.config.includeStack = true
