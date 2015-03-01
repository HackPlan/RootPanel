process.env.NODE_ENV = 'test'
process.env.LOG_LEVEL = 'error'

global._ = require 'underscore'
global.fs = require 'fs'

if fs.existsSync "#{__dirname}/../config.coffee"
  config = require '../config'
else
  config = require '../sample/core.config.coffee'

global.chai = require 'chai'
global.async = require 'async'
global.config = config
global.supertest = require 'supertest'

if process.env.COV_TEST == 'true'
  excludes = ['test', 'node_modules', '.git', 'sample', 'core/static']

  require('coffee-coverage').register
    path: 'relative'
    basePath: "#{__dirname}/../.."
    exclude: excludes.concat config.extends.available_plugins.map (name) ->
      return "plugin/#{name}/test"

global.expect = chai.expect

chai.should()
chai.config.includeStack = true

if process.env.TRAVIS == 'true'
  config.mongodb.user = undefined
  config.mongodb.password = undefined
  config.redis.password = undefined

global.ifEnabled = (plugin_name) ->
  if plugin_name in config.extends.available_plugins
    return describe
  else
    describe.skip

global.unlessTravis = ->
  unless process.env.TRAVIS == 'true'
    return describe
  else
    return describe.skip

require './snippet'
require '../app'
