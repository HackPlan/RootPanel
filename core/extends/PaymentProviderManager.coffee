_ = require 'underscore'
Q = require 'q'

class PaymentProvider
  defaults:
    name: null
    widget: (req) ->
    populateFinancials: (req, financial) -> financial

  constructor: (options) ->
    _.extend @, @defaults, options

module.exports = class PaymentProviderManager
  constructor: ->
    @providers = {}

  register: (options) ->
    {name} = options

    unless name
      throw new Error 'payment provider should have a name'

    if @providers[name]
      throw new Error "payment provider `#{name}` already exists"

    @providers[name] = new PaymentProvider options

  all: ->
    return _.values @providers

  byName: (name) ->
    return @providers[name]

  generateWidgets: (req) ->
    Q.all @providers.map (provider) ->
      provider.widget req
