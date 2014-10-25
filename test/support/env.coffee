process.env.NODE_ENV = 'test'

if process.env.COV_TEST == 'true'
  require('coffee-coverage').register
    path: 'relative'
    basePath: "#{__dirname}/../.."
    exclude: ['test', 'node_modules', '.git', 'sample', 'core/static']

global._ = require 'underscore'
global.fs = require 'fs'
global.async = require 'async'
global.deepmerge = require 'deepmerge'
global.chai = require 'chai'
global.supertest = require 'supertest'

global.expect = chai.expect

chai.should()
chai.config.includeStack = true
