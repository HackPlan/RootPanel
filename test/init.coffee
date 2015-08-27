process.env.NODE_ENV = 'test'
process.env.ROOTPANEL_CONFIG ?= 'sample/core.config.coffee'

chai = require 'chai'
_ = require 'lodash'
Q = require 'q'

_.extend global,
  expect: chai.expect
  Q: Q
  _: _

chai.should()
chai.config.includeStack = true

Q.longStackSupport = true

Root = require '../core'

config = Root.loadConfig()
config.mongodb.name = 'RootPanel-test'

global.root = new Root config
global.helpers = require './helpers'

root.start()
