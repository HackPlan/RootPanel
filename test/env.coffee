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
      result = ['test', 'node_modules', '.git', 'sample', 'core/static', 'migration/database']

      for plugin_name in _.union config.plugin.available_extensions, config.plugin.available_services
        result.push "plugin/#{plugin_name}/test"

      return result

global.expect = chai.expect

chai.should()
chai.config.includeStack = true

config.web.listen = 12558

if process.env.TRAVIS == 'true'
  config.mongodb.user = undefined
  config.mongodb.password = undefined
  config.redis.password = undefined
  config.ssh.id_key = '/home/travis/.ssh/id_rsa'

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
