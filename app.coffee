#!/usr/bin/env coffee

global.app = exports

app.libs =
  _: require 'underscore'
  async: require 'async'
  bodyParser: require 'body-parser'
  cookieParser: require 'cookie-parser'
  copy: require 'copy-to'
  csrf: require 'csrf'
  crypto: require 'crypto'
  depd: require 'depd'
  express: require 'express'
  fs: require 'fs'
  harp: require 'harp'
  markdown: require('markdown').markdown
  middlewareInjector: require 'middleware-injector'
  mongoose: require 'mongoose'
  morgan: require 'morgan'
  nodemailer: require 'nodemailer'
  path: require 'path'
  redis: require 'redis'
  redisStore: require 'connect-redis'
  expressSession: require 'express-session'
  mongooseUniqueValidator: require 'mongoose-unique-validator'

  ObjectId: (require 'mongoose').Schema.Types.ObjectId
  Mixed: (require 'mongoose').Schema.Types.Mixed

{cookieParser, copy, crypto, bodyParser, depd, express, fs, harp, middlewareInjector, mongoose} = exports.libs
{morgan, nodemailer, path, redis} = exports.libs

app.logger = do ->
  unless process.env.NODE_ENV == 'test'
    return console

  return {
    log: ->
    error: console.error
  }

app.package = require './package'
app.deprecate = depd 'rootpanel'

do ->
  config_path = path.join __dirname, 'config.coffee'

  unless fs.existsSync config_path
    unless process.env.TRAVIS == 'true'
      app.deprecate 'config.coffee not found, copy sample config to ./config.coffee'

      default_config = 'core'
    else
      default_config = 'travis-ci'

    fs.writeFileSync config_path, fs.readFileSync path.join __dirname, "./sample/#{default_config}.config.coffee"

  fs.chmodSync config_path, 0o750

config = require './config'

if process.env.NODE_ENV == 'test'
  config.web.listen = require('./sample/travis-ci.config').web.listen

do  ->
  if fs.existsSync config.web.listen
    fs.unlinkSync config.web.listen

  session_key_path = path.join __dirname, 'session.key'

  unless fs.existsSync session_key_path
    fs.writeFileSync session_key_path, crypto.randomBytes(48).toString('hex')
    fs.chmodSync session_key_path, 0o750

app.config = config
app.db = require './core/db'
app.utils = require './core/utils'
app.pluggable = require './core/pluggable'

app.models = {}

require './core/model/Account'
require './core/model/Financials'
require './core/model/CouponCode'
require './core/model/Notification'
require './core/model/SecurityLog'
require './core/model/Ticket'

app.pluggable.initializePlugins()

app.templates = require './core/templates'
app.i18n = require './core/i18n'
app.cache = require './core/cache'
app.billing = require './core/billing'
app.middleware = require './core/middleware'
app.notification = require './core/notification'

app.redis = redis.createClient 6379, '127.0.0.1',
  auth_pass: config.redis.password

app.mailer = nodemailer.createTransport config.email.account
app.express = express()

unless process.env.NODE_ENV == 'test'
  app.express.use morgan 'dev'

app.express.use bodyParser.json()
app.express.use cookieParser()
app.express.use middlewareInjector

app.express.use app.middleware.errorHandling
app.express.use app.middleware.session()
app.express.use app.middleware.csrf()
app.express.use app.middleware.authenticate
app.express.use app.middleware.accountHelpers

app.express.set 'views', path.join(__dirname, 'core/view')
app.express.set 'view engine', 'jade'

app.express.get '/locale/:language?', app.i18n.downloadLocales

app.express.use '/account', require './core/router/account'
app.express.use '/billing', require './core/router/billing'
app.express.use '/ticket', require './core/router/ticket'
app.express.use '/coupon', require './core/router/coupon'
app.express.use '/admin', require './core/router/admin'
app.express.use '/panel', require './core/router/panel'

app.express.get '/', (req, res) ->
  unless res.headerSent
    res.redirect '/panel/'

app.express.use harp.mount './core/static'

app.express.listen config.web.listen, ->
  app.started = true

  if fs.existsSync config.web.listen
    fs.chmodSync config.web.listen, 0o770

  app.logger.log "RootPanel start at #{config.web.listen}"
