process.env.NODE_ENV = 'test'

global.config = require '../config'

global._ = require 'underscore'
global.fs = require 'fs'
global.async = require 'async'
global.deepmerge = require 'deepmerge'
global.chai = require 'chai'
global.supertest = require 'supertest'
global.ObjectId = (require 'mongoose').Types.ObjectId

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

global.created_objects =
  accounts: []
  couponcodes: []
  tickets: []

global.namespace = {}

chai.should()
chai.config.includeStack = true

config.web.listen = 12558

if process.env.TRAVIS == 'true'
  config.mongodb.user = undefined
  config.mongodb.password = undefined

  config.redis.password = undefined
