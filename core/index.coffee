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
  app.use (req, res, next) ->
    req.inject = (dependency, callback) ->
      if req.injected
        dependency = _.reject dependency, (item) ->
          return item in req.injected

      async.eachSeries dependency, (item, callback) ->
        req.injected = [] unless req.injected
        req.injected.push item
        item req, res, callback
      , callback

    next()

  app.use '/account', require './router/account'
  app.use '/admin', require './router/admin'
  app.use '/panel', require './router/panel'

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
