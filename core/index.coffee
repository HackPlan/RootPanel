connect = require 'connect'
path = require 'path'
harp = require 'harp'
fs = require 'fs'
mongomin = require 'mongo-min'
redis = require 'redis'

global._ = require 'underscore'
global.ObjectID = require('mongodb').ObjectID
global.express = require 'express'
global.async = require 'async'

global.app = express()
global.config = require './../config'
global.i18n = require './i18n'
global.utils = require './router/utils'

if fs.existsSync(config.web.listen)
  fs.unlinkSync config.web.listen

bindRouters = (app) ->
  app.use require 'middleware-injector'

  app.use '/', require './router/index'
  app.use '/account', require './router/account'
  app.use '/admin', require './router/admin'
  app.use '/panel', require './router/panel'
  app.use '/plan', require './router/plan'
  app.use '/ticket', require './router/ticket'
  app.use '/wiki', require './router/wiki'
  app.use '/public', require './router/public'
  app.use '/bitcoin', require './router/bitcoin'

  plugin = require './plugin'
  plugin.loadPlugins app

exports.connectDatabase = (callback) ->
  if global.app?.db
    return callback null, app.db

  app.redis = redis.createClient 6379, '127.0.0.1',
    auth_pass: config.redis_password

  {user, password, host, name} = config.mongodb
  mongomin "mongodb://#{user}:#{password}@#{host}/#{name}", (err, db) ->
    global.app ?= {}
    app.db = db
    callback err, db

exports.runWebServer = ->
  exports.connectDatabase (err) ->
    throw err if err

    i18n.init
      default_language: 'zh_CN'
      available_language: ['zh_CN']

    i18n.load path.join(__dirname, 'locale')

    app.package = require '../package.json'

    app.use connect.json()
    app.use connect.urlencoded()
    app.use connect.cookieParser()
    app.use connect.logger('dev')

    app.use (req, res, next) ->
      res.locals.app = app
      res.locals.moment = require 'moment'
      res.locals.t = i18n.getTranslator 'zh_CN'
      res.locals.mAccount = require './model/account'

      next()

    app.use harp.mount(path.join(__dirname, 'static'))

    app.set 'views', path.join(__dirname, 'view')
    app.set 'view engine', 'jade'

    bindRouters app

    app.listen config.web.listen

unless module.parent
  exports.runWebServer()
