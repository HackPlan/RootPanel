connect = require 'connect'
nodemailer = require 'nodemailer'
path = require 'path'
harp = require 'harp'
fs = require 'fs'
moment = require 'moment-timezone'
redis = require 'redis'
express = require 'express'
{MongoClient} = require 'mongodb'

global.app = express()

config = require './config'

if fs.existsSync config.web.listen
  fs.unlinkSync config.web.listen

fs.chmodSync path.join(__dirname, 'config.coffee'), 0o750

exports.run = ->
  {user, password, host, name} = config.mongodb

  if user and password
    mongodb_uri = "mongodb://#{user}:#{password}@#{host}/#{name}"
  else
    mongodb_uri = "mongodb://#{host}/#{name}"

  MongoClient.connect mongodb_uri, (err, db) ->
    throw err if err
    app.db = db

    app.redis = redis.createClient 6379, '127.0.0.1',
      auth_pass: config.redis_password

    app.mailer = nodemailer.createTransport config.email.account

    app.models =
      mAccount: require './core/model/account'
      mBalanceLog: require './core/model/balance_log'
      mCouponCode: require './core/model/coupon_code'
      mNotification: require './core/model/notification'
      mSecurityLog: require './core/model/security_log'
      mTicket: require './core/model/ticket'

    app.i18n = require './core/i18n'
    app.utils = require './core/utils'
    app.config = require './config'
    app.package = require './package.json'
    app.billing = require './core/billing'
    app.pluggable = require './core/pluggable'
    app.middleware = require './core/middleware'
    app.notification = require './core/notification'
    app.authenticator = require './core/authenticator'

    app.template_data =
      ticket_create_email: fs.readFileSync('./core/template/ticket_create_email.html').toString()
      ticket_reply_email: fs.readFileSync('./core/template/ticket_reply_email.html').toString()

    app.localeVersion = config.i18n.version
    app.use connect.json()
    app.use connect.urlencoded()
    app.use connect.cookieParser()
    app.use connect.logger()

    app.use require 'middleware-injector'
    app.use app.i18n.initI18nData

    app.use (req, res, next) ->
      res.locals.app = app
      res.locals.config = app.config
      res.locals.t = res.t = app.i18n.getTranslator req.cookies.language

      res.locals.selectHook = (name) ->
        return app.pluggable.selectHook req.account, name

      language = req.cookies.language ? config.i18n.default_language
      timezone = req.cookies.timezone ? config.i18n.default_timezone

      res.locals.moment = res.moment = ->
        return moment.apply(@, arguments).locale(language).tz(timezone)

      next()

    app.set 'views', path.join(__dirname, 'core/view')
    app.set 'view engine', 'jade'

    app.get '/locale/:language', app.i18n.downloadLocales

    app.use '/account', require './core/router/account'
    app.use '/billing', require './core/router/billing'
    app.use '/ticket', require './core/router/ticket'
    app.use '/admin', require './core/router/admin'
    app.use '/panel', require './core/router/panel'

    app.pluggable.initializePlugins()

    app.get '/', (req, res) ->
      res.redirect '/panel/'

    app.use harp.mount './core/static'

    app.billing.run()

    app.listen config.web.listen, ->
      fs.chmodSync config.web.listen, 0o770
      console.log "RootPanel start at #{config.web.listen}"

unless module.parent
  exports.run()
