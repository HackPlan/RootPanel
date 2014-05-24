express = require 'express'
connect = require 'connect'
async = require 'async'
_ = require 'underscore'
path = require 'path'
harp = require 'harp'
fs = require 'fs'

config = require './config'
db = require './db'
i18n = require './i18n'

bindRouters = (app) ->
  app.use require 'middleware-injector'

  app.use '/account', require './router/account'
  app.use '/admin', require './router/admin'
  app.use '/panel', require './router/panel'
  app.use '/plan', require './router/plan'
  app.use '/ticket', require './router/ticket'
  app.use '/wiki', require './router/wiki'
  app.use '/public', require './router/public'

  app.get '/', (req, res) ->
    res.redirect '/panel/'

  plugin = require './plugin'
  plugin.loadPlugins app

exports.runWebServer = ->
  db.connect ->
    app = express()

    i18n.init
      default_language: 'zh_CN'
      available_language: ['zh_CN']

    i18n.load path.join(__dirname, 'locale')

    app.use connect.json()
    app.use connect.urlencoded()
    app.use connect.cookieParser()
    app.use connect.logger('dev')

    app.use (req, res, next) ->
      res.locals.app = app
      res.locals.t = i18n.getTranslator 'zh_CN'
      res.locals.mAccount = require './model/account'

      next()

    app.use harp.mount(path.join(__dirname, 'static'))

    app.set 'views', path.join(__dirname, 'view')
    app.set 'view engine', 'jade'

    bindRouters app

    app.listen config.web.port

unless module.parent
  exports.runWebServer()
