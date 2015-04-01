class CouponProvider
  defaults:
    name: null
    validate: (account, coupon) ->
    apply: (account, coupon) ->
    populateCoupon: (coupon, {req}) -> coupon

  constructor: (options) ->
    _.extend @, @defaults, options

module.exports = class CouponProviderManager
  constructor: ->
    @providers = {}

  register: (options) ->
    {name} = options

    unless name
      throw new Error 'coupon provider should have a name'

    if @providers[name]
      throw new Error "coupon provider `#{name}` already exists"

    @providers[name] = new CouponType options

  all: ->
    return _.values @providers

  byName: (name) ->
    return @providers[name]
