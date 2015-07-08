{EventEmitter} = require 'events'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
nodemailer = require 'nodemailer'
Insight = require 'insight'
express = require 'express'
Mabolo = require 'mabolo'
morgan = require 'morgan'
path = require 'path'
fs = require 'q-io/fs'
_ = require 'lodash'
Q = require 'q'

###
  Class: Root object for control RootPanel, An instance is always available as the `root` global.
###
module.exports = class Root extends EventEmitter
  ###
    Public: Find and load configure file.

    * `root_path` {String} e.g. `/home/rpadmin/RootPanel`

    Return {Object}.
  ###
  @findConfig: (root_path) ->
    configPath = path.resolve root_path, 'config.coffee'
    defaultPath = path.resolve root_path, 'sample/core.config.coffee'

    fs.exists(configPath).then (exists) ->
      return require if exists then configPath else defaultPath

  log: console.log

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
  # Public: global {CacheFactory} instance
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

  Plugin: null

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
    @log "new Root #{@package.name} #{@package.version}"

  ###
    Public: Run RootPanel and start web service.

    Return a {Promise}.
  ###
  start: ->
    CacheFactory = require './cache'

    mabolo = new Mabolo mongodbUri @config.mongodb

    _.extend @,
      express: express()
      mabolo: mabolo
      mailer: nodemailer.createTransport @config.email.account

      insight: new Insight
        trackingCode: TRACKING_CODE
        packageName: 'RootPanel'
        pkg: @package

      cache: new CacheFactory @config.redis

    _.extend @,
      Account: mabolo.bind require './model/account'
      Financials: mabolo.bind require './model/financials'
      CouponCode: mabolo.bind require './model/coupon-code'
      Notification: mabolo.bind require './model/notification'
      SecurityLog: mabolo.bind require './model/security-log'
      Ticket: mabolo.bind require './model/ticket'
      Component: mabolo.bind require './model/component'

    HookRegistry = require './registry/hook'
    ViewRegistry = require './registry/view'
    WidgetRegistry = require './registry/widget'
    ComponentRegistry = require './registry/component'
    CouponTypeRegistry = require './registry/coupon-type'
    PaymentProviderRegistry = require './registry/payment-provider'

    _.extend @,
      routers: []

      hooks: new HookRegistry()
      views: new ViewRegistry()
      widgets: new WidgetRegistry()
      components: new ComponentRegistry()
      couponTypes: new CouponTypeRegistry()
      paymentProviders: new PaymentProviderRegistry()

    I18nManager = require './i18n-manager'
    PluginManager = require './plugin-manager'
    ServerManager = require './server-manager'
    BillingManager = require './billing-manager'
    NotificationManager = require './notification-manager'

    _.extend @,
      Plugin: PluginManager.Plugin

    _.extend @,
      i18n: new I18nManager @config.i18n
      plugins: new PluginManager @config.plugins
      servers: new ServerManager @config.server
      billing: new BillingManager @config.billing
      notifications: new NotificationManager()

    @express.use bodyParser.json()
    @express.use cookieParser()

    unless @testing()
      @express.use morgan 'combined'

    middleware = require './middleware'

    @express.use middleware.reqHelpers
    @express.use middleware.session @cache
    @express.use middleware.authenticate
    @express.use middleware.renderHelpers

    @express.use '/admin', require './router/admin'
    @express.use '/panel', require './router/panel'
    @express.use '/tickets', require './router/ticket'
    @express.use '/account', require './router/account'
    @express.use '/components', require './router/component'
    @express.use '/public', express.static @resolve 'public'

    @express.use middleware.errorHandling

    @trackUsage 'root.start'
    @listen()

  listen: ->
    {listen} = @config.web
    @log "Root.listen on #{listen}"

    Q().then ->
      if _.isString listen
        fs.exists(listen).then (exists) ->
          fs.remove(listen) if exists
    .then =>
      Q.Promise (resolve, reject) =>
        @express.listen listen, (err) =>
          if err
            reject err
          else
            @emit 'started'
            resolve()

  testing: ->
    return process.env.NODE_ENV == 'test'

  error: (message, options) ->
    return _.extend new Error message, options

  ###
    Public: Resolve path based on root directory.

    * `arguments...` {String} paths

    return {String}.
  ###
  resolve: ->
    return path.resolve __dirname, '..', arguments...

  ###
    Public: Send usage metrics to Google Analytics.

    * `path` {String} e.g. `root.start`

  ###
  trackUsage: (path) ->
    @log "Root.trackUsage #{path}"
    @insight.track path.split('.')...

# Private: This code used to send anonymous usage metrics to RootPanel developers.
TRACKING_CODE = 'UA-49193300-7'

mongodbUri = ({user, password, host, name}) ->
  if user and password
    return "mongodb://#{user}:#{password}@#{host}/#{name}"
  else
    return "mongodb://#{host}/#{name}"
