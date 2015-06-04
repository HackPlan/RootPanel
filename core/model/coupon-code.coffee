Mabolo = require 'mabolo'
_ = require 'lodash'
Q = require 'q'

utils = require '../utils'

{ObjectID} = Mabolo

###
  Model: Apply log of CouponCode,
  Embedded as a array at `apply_log` of {CouponCode}.
###
ApplyLog = Mabolo.model 'ApplyLog',
  # Public: Related account
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  created_at:
    type: Date
    default: -> new Date()

###
  Model: CouponCode.
###
module.exports = CouponCode = Mabolo.model 'CouponCode',
  # Public: Code of coupon
  code:
    required: true
    unique: true
    type: String

  # Public: Current available times
  available_times:
    type: Number
    default: 1

  # Public: Expired Date
  expired_at:
    type: Date

  # Public: {CouponType} of coupon
  type:
    required: true
    type: String
    enum: ['cash']

  # Public: Custom options of coupon, used by couponType
  options:
    type: Object

  # Public: Apply log of coupon
  apply_log: [ApplyLog]

CouponCode.ensureIndex
  code: 1
,
  unique: true

CouponCode.findByCode = (code, options...) ->
  @findOne code: code, options...

###
  Public: Create coupons.

  * `coupon` {Object}

    * `type` {String}
    * `options` (optional) {Object}
    * `expired_at` (optional) {Date}
    * `available_times` (optional) {Number}

  * `count` {Number}

  Return {Promise} resolve with array of {CouponCode}.
###
CouponCode.createCoupons = ({type, options, expired_at, available_times}, count) ->
  Q.all [1 .. count].map =>
    @create
      code: utils.randomString 16
      type: type
      options: options
      expired_at: expired_at
      available_times: available_times

CouponCode::pick = ->
  return _.omit @, 'apply_log'

###
  Public: Check availability for specified account.

  * `account` {Account}

  Return {Promise} resolve with {Boolean}.
###
CouponCode::validateCoupon = (account) ->
  @populate().then ->
    if @available_times != undefined and @available_times <= 0
      return false

    if @expired and new Date() > @expired
      return false

    @provider.validate account, @

###
  Public: Apply coupon for specified account.

  * `account` {Account}

  Return {Promise}.
###
CouponCode::apply = (account) ->
  @validate(account).then (available) ->
    unless available
      throw new Error 'coupon_unavailable'
  .then =>
    @provider.apply account, @
  .then =>
    @update
      $inc:
        available_times: -1
      $push:
        apply_log:
          account_id: account._id
          created_at: new Date()

###
  Public: Populate.

  This function will populate following fields:

  * `provider`: {CouponType} from `type`.

  Return {Promise}.
###
CouponCode::populate = ({req} = {}) ->
  if @provider
    return Q @

  @provider = root.couponTypes.byName @type

  if @provider
    @provider.populateCoupon @, req: req
  else
    return Q.reject new Error 'provider_not_found'
