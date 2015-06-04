_ = require 'lodash'
Q = require 'q'

###
  Class: Payment provider, Managed by {PaymentProviderRegistry}.
###
class PaymentProvider
  defaults:
    name: null
    populateFinancials: (req, financial) -> financial

  constructor: (options) ->
    _.extend @, @defaults, options

###
  Public: Payment provider registry,
  You can access a global instance via `root.paymentProviders`.
###
module.exports = class PaymentProviderRegistry
  constructor: ->
    @providers = {}

  ###
    Public: Register a payment provider.

    * `name` {String}
    * `options` {Object}

      * `plugin` {Plugin}
      * `widget` {Function} Received {ClientRequest}, return {Promise} resolve with html.
      * `populateFinancials` {Function} Received {ClientRequest} and {Financials}, Return {Promise}.

    Return {PaymentProvider}.
  ###
  register: (name, options) ->
    unless name
      throw new Error 'Payment provider should have a name'

    if @providers[name]
      throw new Error "Payment provider `#{name}` already exists"

    @providers[name] = new PaymentProvider _.extend options,
      name: name

  ###
    Public: Get all payment providers.

    Return {Array} of {PaymentProvider}.
  ###
  all: ->
    return _.values @providers

  ###
    Public: Get specified provider.

    * `name` {String}

    Return {PaymentProvider}.
  ###
  byName: (name) ->
    return @providers[name]

PaymentProviderRegistry.PaymentProvider = PaymentProvider
