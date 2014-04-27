express = require 'express'
connect = require 'connect'
path = require 'path'
fs = require 'fs'

config = require './config'
db = require './db'
i18n = require './i18n'

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

      next()

    app.use (req, res, next) ->
      if req.headers['x-token']
        req.token = req.headers['x-token']
      else
        req.token = req.cookies.token

      next()

    app.use express.static(path.join(__dirname, 'static'))

    app.set 'views', path.join(__dirname, 'view')
    app.set 'view engine', 'jade'

    api = require './api'
    api.bind app

    plugin = require './plugin'
    plugin.loadPlugins()

    app.listen config.web.port

unless module.parent
  exports.runWebServer()
