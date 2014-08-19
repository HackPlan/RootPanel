connect = require 'connect'
path = require 'path'
harp = require 'harp'
fs = require 'fs'
moment = require 'moment'
mongomin = require 'mongo-min'
redis = require 'redis'

global._ = require 'underscore'
global.ObjectID = require('mongodb').ObjectID
global.express = require 'express'
global.async = require 'async'

global.app = express()
global.config = require './config'
global.i18n = require './core/i18n'
global.utils = require './core/router/utils'

if fs.existsSync(config.web.listen)
  fs.unlinkSync config.web.listen

bindRouters = (app) ->
  app.use require 'middleware-injector'

  app.use '/', require './core/router/index'

  for module_name in ['account', 'admin', 'panel', 'plan', 'ticket', 'wiki', 'bitcoin']
    app.use "/#{module_name}", require './core/router/' + module_name

  plugin = require './core/plugin'
  plugin.loadPlugins app

exports.connectDatabase = (callback) ->
  {user, password, host, name} = config.mongodb
  mongomin "mongodb://#{user}:#{password}@#{host}/#{name}", (err, db) ->
    app.db = db

    app.redis = redis.createClient 6379, '127.0.0.1',
      auth_pass: config.redis_password

    callback err

exports.runWebServer = ->
  exports.connectDatabase (err) ->
    throw err if err

    i18n.init
      default_language: 'zh_CN'
      available_language: ['zh_CN']

    i18n.load path.join(__dirname, 'core/locale')

    app.package = require './package.json'

    app.use connect.json()
    app.use connect.urlencoded()
    app.use connect.cookieParser()
    app.use connect.logger('dev')

    moment.locale 'zh_CN'

    app.use (req, res, next) ->
      res.locals.app = app
      res.locals.moment = moment
      res.locals.t = i18n.getTranslator 'zh_CN'
      res.locals.mAccount = require './core/model/account'

      next()

    app.set 'views', path.join(__dirname, 'core/view')
    app.set 'view engine', 'jade'

    bindRouters app

    app.use harp.mount(path.join(__dirname, 'core/static'))

    app.listen config.web.listen

unless module.parent
  exports.runWebServer()
