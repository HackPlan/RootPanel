{Router} = require 'express'
path = require 'path'
_ = require 'lodash'

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

  ###
  constructor: (Plugin, {name, path, config, package: pkg}) ->
    @owner = new Plugin @, config

    _.extend @owner,
      name: name
      path: path

  ###
    Public: Get owner plugin.

    Return {Plugin}.
  ###
  plugin: ->
    return @owner

  router: (path) ->
    router = new Router()
    root.express.use path, router

    root.routers.push
      path: path
      router: router
      plugin: @owner

    return router

  ###
    Public: Register a hook, proxy of {HookRegistry::register}.
  ###
  hook: (path, options) ->
    return root.hooks.register path, _.extend options,
      plugin: @owner

  ###
    Public: Register a view, proxy of {ViewRegistry::register}.
  ###
  view: (view, options) ->
    return root.views.register view, _.extend options,
      plugin: @owner

  ###
    Public: Register a widget, proxy of {WidgetRegistry::register}.
  ###
  widget: (view, options) ->
    return root.widgets.register view, _.extend options,
      plugin: @owner

  ###
    Public: Register a component, proxy of {ComponentRegistry::register}.
  ###
  component: (name, options) ->
    return root.components.register name, _.extend options,
      plugin: @owner

  ###
    Public: Register a coupon type, proxy of {CouponTypeRegistry::register}.
  ###
  couponType: (name, options) ->
    return root.couponTypes.register name, _.extend options,
      plugin: @owner

  ###
    Public: Register a payment provider, proxy of {PaymentProviderRegistry::register}.
  ###
  paymentProvider: (name, options) ->
    return root.paymentProviders.register name, _.extend options,
      plugin: @owner

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
