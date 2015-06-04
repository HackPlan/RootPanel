_ = require 'lodash'

###
  Class: Coupon type, Managed by {CouponTypeRegistry}
###
class CouponType
  defaults:
    name: null
    validate: (account, coupon) ->
    apply: (account, coupon) ->
    populateCoupon: (coupon, {req}) -> coupon

  constructor: (options) ->
    _.extend @, @defaults, options

###
  Registry: Extend type of coupons.
  You can access a global instance via `root.couponTypes`.
###
module.exports = class CouponTypeRegistry
  constructor: ->
    @providers = {}

  ###
    Public: Register a coupon type.

    * `name` {String}
    * `options` {Object}

      * `plugin` {Plugin}
      * `validate` {Function} Received {Account} and {CouponCode}, return {Promise}.
      * `apply` {Function} Received {Account} and {CouponCode}, return {Promise}.
      * `populateCoupon` {Function} Received {CouponCode} and `{req}`, return {Promise}.

    Return {CouponType}.
  ###
  register: (name, options) ->
    unless name
      throw new Error 'Coupon type should have a name'

    if @providers[name]
      throw new Error "Coupon type `#{name}` already exists"

    @providers[name] = new CouponType _.extend options,
      name: name

  ###
    Public: Get all coupon type.

    Return {Array} of {CouponType}.
  ###
  all: ->
    return _.values @providers

  ###
    Public: Get specified type.

    * `name` {String}

    Return {CouponType}.
  ###
  byName: (name) ->
    return @providers[name]

CouponTypeRegistry.CouponType = CouponType
