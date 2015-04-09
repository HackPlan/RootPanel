_ = require 'lodash'

class CouponType
  defaults:
    name: null
    validate: (account, coupon) ->
    apply: (account, coupon) ->
    populateCoupon: (coupon, {req}) -> coupon

  constructor: (options) ->
    _.extend @, @defaults, options

###
  Public: Extend type of coupons.
  You can access a global instance via `root.couponTypes`.
###
module.exports = class CouponTypeRegistry
  constructor: ->
    @providers = {}

  register: (options) ->
    {name} = options

    unless name
      throw new Error 'coupon provider should have a name'

    if @providers[name]
      throw new Error "coupon provider `#{name}` already exists"

    @providers[name] = new CouponType _.extend options

  all: ->
    return _.values @providers

  byName: (name) ->
    return @providers[name]
