process.env.NODE_ENV = 'test'
process.env.LOG_LEVEL = 'error'

global.config = require '../config'

global._ = require 'underscore'
global.fs = require 'fs'
global.async = require 'async'
global.chai = require 'chai'
global.supertest = require 'supertest'

if process.env.COV_TEST == 'true'
  require('coffee-coverage').register
    path: 'relative'
    basePath: "#{__dirname}/../.."
    exclude: do ->
      excludes = ['test', 'node_modules', '.git', 'sample', 'core/static', 'migration']

      for plugin_name in _.union config.plugin.available_extensions, config.plugin.available_services
        excludes.push "plugin/#{plugin_name}/test"

      return excludes

global.expect = chai.expect

chai.should()
chai.config.includeStack = true

if process.env.TRAVIS == 'true'
  config.mongodb.user = undefined
  config.mongodb.password = undefined
  config.redis.password = undefined

global.ifEnabled = (plugin_name) ->
  if plugin_name in config.plugin.available_plugins
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
