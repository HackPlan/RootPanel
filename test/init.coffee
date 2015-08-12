process.env.NODE_ENV = 'test'

chai = require 'chai'
_ = require 'lodash'
Q = require 'q'

Root = require '../core'

global.config = require '../sample/core.config.coffee'
global.helpers = require './helpers'
global.root = new Root config

root.start()

_.extend global,
  expect: chai.expect
  Q: Q
  _: _

chai.should()
chai.config.includeStack = true

Q.longStackSupport = true
