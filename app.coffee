connect = require 'connect'
nodemailer = require 'nodemailer'
path = require 'path'
harp = require 'harp'
fs = require 'fs'
moment = require 'moment'
redis = require 'redis'

global.app = express()

if fs.existsSync config.web.listen
  fs.unlinkSync config.web.listen

fs.chmodSync path.join(__dirname, 'config.coffee'), 0o750

bindRouters = ->
  app.use require 'middleware-injector'

  for module_name in ['account', 'admin', 'panel', 'plan', 'ticket']
    app.use "/#{module_name}", require './core/router/' + module_name

  pluggable.initializePlugins()

  app.use '/wiki', require './core/router/wiki'

  app.get '/', (req, res) ->
    res.redirect '/panel/'

exports.run = ->
  {user, password, host, name} = config.mongodb

  MongoClient.connect "mongodb://#{user}:#{password}@#{host}/#{name}", (err, db) ->
    throw err if err
    app.db = db

    app.redis = redis.createClient 6379, '127.0.0.1',
      auth_pass: config.redis_password

    app.mailer = nodemailer.createTransport config.email.account

    app.i18n = require './core/i18n'
    app.utils = require './core/utils'
    app.config = require '../config'
    app.package = require './package.json'
    app.pluggable = require './core/pluggable'
    app.middleware = require './core/middleware'
    app.authenticator = require './core/authenticator'

    app.models =
      mAccount: require './model/account'
      mBalanceLog: require './model/balance_log'
      mCouponCode: require './model/coupon_code'
      mNotification: require './model/notification'
      mSecurityLog: require './model/security_log'
      mTicket: require './model/tickets'

    app.use connect.json()
    app.use connect.urlencoded()
    app.use connect.cookieParser()
    app.use connect.logger('dev')

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
