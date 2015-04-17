{Router} = require 'express'

###
  Class: Abstract plugin, managed by {PluginManager}.
###
class Plugin
  # Public: {String}
  name: null
  # Public: {String}
  path: null
  # Public: {Array} or {String}
  dependencies: []

  ###
    Public: Constructor.

    * `injector` {Injector}

  ###
  constructor: (@injector) ->

  ###
    Public: Get translator of plugin.

    * `language` {String} or {ClientRequest}

    Return {Function} `(name, params) -> String`.
  ###
  getTranslator: (language) ->

###
  Class: Private injector of {Plugin}.
###
class Injector
  ###
    Public: Constructor.

    * `Plugin` Constructor {Function} of {Plugin}.
    * `plugin` {Object}

      * `name` {String}
      * `path` {String}
      * `config` {Object}
      * `package` {Object}
      * `registries` {Root}

  ###
  constructor: (Plugin, {name, path, config, package: pkg, @registries}) ->
    @plugin = new Plugin @, config

    _.extend @plugin,
      name: name
      path: path

  ###
    Public: Get owner plugin.

    Return {Plugin}.
  ###
  plugin: ->
    return @plugin

  router: (path) ->
    router = express.Router()
    root.express.use path, router

    @registries.routers.push
      path: path
      router: router
      plugin: @plugin

    return router

  ###
    Public: Register a hook, proxy of {HookRegistry::register}.
  ###
  hook: (path, options) ->
    return @registries.hooks.register path, _.extend options,
      plugin: @plugin

  ###
    Public: Register a view, proxy of {ViewRegistry::register}.
  ###
  view: (view, options) ->
    return @registries.views.register view, _.extend options,
      plugin: @plugin

  ###
    Public: Register a widget, proxy of {WidgetRegistry::register}.
  ###
  widget: (view, options) ->
    return @registries.widgets.register view, _.extend options,
      plugin: @plugin

  ###
    Public: Register a component, proxy of {ComponentRegistry::register}.
  ###
  component: (name, options) ->
    return @extend.components.register name, _.extend options,
      plugin: @plugin

  ###
    Public: Register a coupon type, proxy of {CouponTypeRegistry::register}.
  ###
  couponType: (name, options) ->
    return @extend.couponTypes.register name, _.extend options,
      plugin: @plugin

  ###
    Public: Register a payment provider, proxy of {PaymentProviderRegistry::register}.
  ###
  paymentProvider: (name, options) ->
    return @extend.paymentProviders.register name, _.extend options,
      plugin: @plugin

###
  Manager: Plugin manager,
  You can access a global instance via `root.plugins`.
###
module.exports = class PluginManager
  constructor: (@config) ->
    @plugins = {}

    for name, config of @config
      if config.enable
        @add name, path.join(__dirname, '../plugins', name), config

  ###
    Public: Add a plugin.

    * `name` {String}
    * `path` {String}
    * `config` {Object} `plugins.$name` of config object.

    Return {Plugin}.
  ###
  add: (name, path, config) ->
    if @plugins[name]
      throw new Error "Plugin `#{name}` already exists"

    injector = new Injector require(path),
      name: name
      path: path
      config: config
      package: require "#{path}/package.json"
      registries: root

    @plugins[name] = injector.plugin()

  ###
    Public: Get all plugins.

    Return {Array} of {Plugin}.
  ###
  all: ->
    return _.values @plugins

  ###
    Public: Get specified plugin.

    * `name` {String}

    Return {Plugin}.
  ###
  byName: (name) ->
    return @plugins[name]
