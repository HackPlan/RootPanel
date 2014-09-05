connect = require 'connect'
path = require 'path'
harp = require 'harp'
fs = require 'fs'
moment = require 'moment'
mongomin = require 'mongo-min'
redis = require 'redis'

global.app = express()
global.config = require './config'
global.i18n = require './core/i18n'
global.utils = require './core/router/utils'
global.pluggable = require './core/pluggable'

if fs.existsSync config.web.listen
  fs.unlinkSync config.web.listen

fs.chmodSync path.join(__dirname, 'config.coffee'), 0o750

bindRouters = ->
  app.use require 'middleware-injector'

  for module_name in ['account', 'admin', 'panel', 'plan', 'ticket', 'bitcoin']
    app.use "/#{module_name}", require './core/router/' + module_name

  pluggable.initializePlugins()

  app.use '/wiki', require './core/router/wiki'

  app.get '/', (req, res) ->
    res.redirect '/panel/'

exports.connectDatabase = (callback) ->
  {user, password, host, name} = config.mongodb
  mongomin "mongodb://#{user}:#{password}@#{host}/#{name}", (err, db) ->
    app.db = db

    app.redis = redis.createClient 6379, '127.0.0.1',
      auth_pass: config.redis_password

    callback err

exports.run = ->
  exports.connectDatabase (err) ->
    throw err if err

    app.package = require './package.json'

    app.use connect.json()
    app.use connect.urlencoded()
    app.use connect.cookieParser()
    app.use connect.logger('dev')

    moment.locale 'zh_CN'

    app.use (req, res, next) ->
      res.locals.app = app
      res.locals.t = i18n.getTranslator req.cookies.language
      res.moment = moment().locale(req.cookies.language ? config.i18n.default_language).tz(req.cookies.timezone ? config.i18n.default_timezone)

      next()

    app.set 'views', path.join(__dirname, 'core/view')
    app.set 'view engine', 'jade'

    bindRouters app

    app.use harp.mount './core/static'

    app.listen config.web.listen, ->
      fs.chmodSync config.web.listen, 0o770

unless module.parent
  exports.run()
