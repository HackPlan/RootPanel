{EventEmitter} = require 'events'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
nodemailer = require 'nodemailer'
Insight = require 'insight'
express = require 'express'
Mabolo = require 'mabolo'
morgan = require 'morgan'
path = require 'path'
harp = require 'harp'
fs = require 'q-io/fs'
_ = require 'lodash'

###
  Class: Root object for control RootPanel, An instance is always available as the `root` global.
###
module.exports = class Root extends EventEmitter
  ###
    Public: Find and load configure file.

    * `rootPath` {String} e.g. `/home/rpadmin/RootPanel`

    Return {String}.
  ###
  @findConfig: (rootPath) ->
    configPath = path.resolve rootPath, '../config.coffee'
    defaultPath = path.resolve rootPath, '../sample/config.coffee'

    fs.exists(configPath).then (exists) ->
      fs.read if exists then configPath else defaultPath

  # Public: Config object
  config: null
  # Public: Node package object
  package: null
  # Public: express application
  express: null
  # Public: nodemailer instance
  mailer: null
  # Public: {Mabolo} instance
  mabolo: null
  # Public: {Insight} instance
  insight: null
  # Public: global {Cache} instance
  cache: null

  # Public: {Account} Model
  Account: null
  # Public: {Financials} Model
  Financials: null
  # Public: {CouponCode} Model
  CouponCode: null
  # Public: {Notification} Model
  Notification: null
  # Public: {SecurityLog} Model
  SecurityLog: null
  # Public: {Ticket} Model
  Ticket: null
  # Public: {Component} Model
  Component: null

  # Public: global {HookRegistry} instance
  hooks: null
  # Public: global {ViewRegistry} instance
  views: null
  # Public: global {WidgetRegistry} instance
  widgets: null
  # Public: global {ComponentRegistry} instance
  components: null
  # Public: global {CouponTypeRegistry} instance
  couponTypes: null
  # Public: global {PaymentProviderRegistry} instance
  paymentProviders: null

  # Public: global {I18nManager} instance
  i18n: null
  # Public: global {PluginManager} instance
  plugins: null
  # Public: global {ServerManager} instance
  servers: null
  # Public: global {BillingManager} instance
  billing: null
  # Public: global {NotificationManager} instance
  notifications: null

  ###
    Public: Construct a RootPanel instance.

    * `config` {Object} Configure object
    * `package` {Object} Node package object

  ###
  constructor: (@config, @package) ->
    @package ?= require '../package'

    Cache = require './cache'

    HookRegistry = require './registry/hook'
    ViewRegistry = require './registry/view'
    WidgetRegistry = require './registry/widget'
    ComponentRegistry = require './registry/component'
    CouponTypeRegistry = require './registry/coupon-type'
    PaymentProviderRegistry = require './registry/payment-provider'

    I18nManager = require './i18n-manager'
    PluginManager = require './plugin-manager'
    ServerManager = require './server-manager'
    BillingManager = require './billing-manager'
    NotificationManager = require './notification-manager'

    _.extend @,
      express: express()
      mailer: nodemailer.createTransport @config.email.account
      mabolo: new Mabolo mongodbUri @config.mongodb

      insight: new Insight
        trackingCode: TRACKING_CODE
        pkg: @package

      cache: new Cache()

      Account: require './model/account'
      Financials: require './model/financials'
      CouponCode: require './model/coupon-code'
      Notification: require './model/notification'
      SecurityLog: require './model/security-log'
      Ticket: require './model/ticket'
      Component: require './model/component'

      hooks: new HookRegistry()
      views: new ViewRegistry()
      widgets: new WidgetRegistry()
      components: new ComponentRegistry()
      couponTypes: new CouponTypeRegistry()
      paymentProviders: new PaymentProviderRegistry()

      i18n: new I18nManager @config.i18n
      plugins: new PluginManager @config.plugins
      servers: new ServerManager @config.server
      billing: new BillingManager @config.billing
      notifications: new NotificationManager()

    @express.use bodyParser.json()
    @express.use cookieParser()
    @express.use morgan 'combined'

    middleware = require './middleware'

    @express.use middleware.reqHelpers
    @express.use middleware.session()
    @express.use middleware.csrf()
    @express.use middleware.authenticate
    @express.use middleware.renderHelpers

    @express.use '/admin', require './router/admin'
    @express.use '/panel', require './router/panel'
    @express.use '/ticket', require './router/ticket'
    @express.use '/account', require './router/account'
    @express.use '/component', require './router/component'

    @express.use '/bower_components', express.static @resolve '../bower_components'
    @express.use harp.mount @resolve 'static'

    @express.get '/', (req, res) ->
      res.redirect '/panel/'

  ###
    Public: Run RootPanel and start web service.

    Return a {Promise}.
  ###
  start: ->
    @trackUsage 'root.start'

    fs.exists(@config.web.listen).then (exists) ->
      fs.unlink(@config.web.listen) if exists
    .then ->
      Q.Promise (resolve, reject) =>
        @express.listen @config.web.listen, (err) =>
          return reject err if err

          @emit 'started'
          resolve()

  ###
    Public: Resolve path based on core directory.

    * `arguments...` {String} paths

    return {String}.
  ###
  resolve: ->
    return path.resolve __dirname, arguments...

  ###
    Public: Send usage metrics to Google Analytics.

    * `path` {String} e.g. `root.start`

  ###
  trackUsage: (path) ->
    @insight.track path.split('.')...

# Private: This code used to send anonymous usage metrics to RootPanel developers.
TRACKING_CODE = 'UA-49193300-7'

mongodbUri = ({user, password, host, name}) ->
  if user and password
    return "mongodb://#{user}:#{password}@#{host}/#{name}"
  else
    return "mongodb://#{host}/#{name}"
