#!/usr/bin/env coffee

global.app = exports

app.libs =
  _: require 'underscore'
  async: require 'async'
  bodyParser: require 'body-parser'
  cookieParser: require 'cookie-parser'
  depd: require 'depd'
  express: require 'express'
  fs: require 'fs'
  middlewareInjector: require 'middleware-injector'
  mongoose: require 'mongoose'
  morgan: require 'morgan'
  nodemailer: require 'nodemailer'
  path: require 'path'
  redis: require 'redis'

{cookieParser, bodyParser, depd, express, fs, nodemailer, path} = exports.libs

app.package = require './package'
app.deprecate = depd 'rootpanel'

do ->
  config_path = path.join __dirname, 'config.coffee'

  unless fs.existsSync config_path
    default_config_path = path.join __dirname, './sample/core.config.coffee'
    fs.writeFileSync config_file_path, fs.readFileSync default_config_path
    app.deprecate 'config.coffee not found, copy sample config to ./config.coffee'

  fs.chmodSync config_path, 0o750

config = require './config'

do  ->
  if fs.existsSync config.web.listen
    fs.unlinkSync config.web.listen

  session_key_path = path.join __dirname, 'session.key'

  unless fs.existsSync session_key_path
    fs.writeFileSync session_key_path, crypto.randomBytes(48).toString('hex')

app.config = config
app.db = require './core/db'
app.templates = require './core/templates'
app.i18n = require './core/i18n'
app.utils = require './core/utils'
app.cache = require './core/cache'
app.config = require './config'
app.package = require './package.json'
app.billing = require './core/billing'
app.pluggable = require './core/pluggable'
app.middleware = require './core/middleware'
app.notification = require './core/notification'
app.authenticator = require './core/authenticator'

app.mailer = nodemailer.createTransport config.email.account
app.express = express()

app.redis = redis.createClient 6379, '127.0.0.1',
  auth_pass: config.redis.password

app.schemas = {}

app.models =
  Account: require './core/model/account'
  BalanceLog: require './core/model/balance_log'
  CouponCode: require './core/model/coupon_code'
  Notification: require './core/model/notification'
  SecurityLog: require './core/model/security_log'
  Ticket: require './core/model/ticket'

app.use bodyParser.json()
app.use morgan 'dev'
app.use cookieParser()
app.use middlewareInjector

app.use session
  store: new RedisStore
    client: app.redis

  resave: true
  saveUninitialized: true
  secret: fs.readFileSync(path.join __dirname, 'session.key').toString()

app.use (req, res, next) ->
  unless req.session.csrf_secret
    csrf.secret (err, secret) ->
      req.session.csrf_secret = secret
      req.session.csrf_token = csrf.create secret
      next()

  next()

app.use (req, res, next) ->
  unless req.method == 'GET'
    unless csrf.verify req.session.csrf_secret, req.body.csrf_token
      return res.status(403).send
        error: 'invalid_csrf_token'

  next()

app.use (req, res, next) ->
  req.res = res

  res.language = req.cookies.language ? config.i18n.default_language
  res.timezone = req.cookies.timezone ? config.i18n.default_timezone

  res.locals =
    config: config
    app: app
    req: req
    res: res

    t: app.i18n.getTranslator req

    selectHook: (name) ->
      return app.pluggable.selectHook req.account, name

    moment: ->
      return moment.apply(@, arguments).locale(res.language).tz(res.timezone)

  res.t = res.locals.t
  res.moment = res.locals.moment

  res.locals.config.web.name = res.t app.config.web.t_name

  next()

app.use app.middleware.accountInfo

app.set 'views', path.join(__dirname, 'core/view')
app.set 'view engine', 'jade'

app.get '/locale/:language?', app.i18n.downloadLocales

app.use '/account', require './core/router/account'
app.use '/billing', require './core/router/billing'
app.use '/ticket', require './core/router/ticket'
app.use '/admin', require './core/router/admin'
app.use '/panel', require './core/router/panel'

app.pluggable.initializePlugins()

app.get '/', (req, res) ->
  unless res.headerSent
    res.redirect '/panel/'

app.use harp.mount './core/static'

app.billing.run()

app.listen config.web.listen, ->
  fs.chmodSync config.web.listen, 0o770
  console.log "RootPanel start at #{config.web.listen}"
