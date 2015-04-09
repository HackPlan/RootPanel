_ = require 'lodash'
Q = require 'q'

utils = require '../utils'

{mabolo} = root
{ObjectID} = mabolo

###
  Model: Apply Log of CouponCode,
  Embedded as a array at `apply_log` of {CouponCode}.
###
ApplyLog = mabolo.model 'ApplyLog',
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
CouponCode = mabolo.model 'CouponCode',
  # Public: Code of coupon
  code:
    required: true
    unique: true
    type: String

  # Public: Current available times
  available_times:
    type: Number

  # Public: Expired Date
  expired_at:
    type: Date

  # Public: {CouponType} of coupon
  type:
    required: true
    type: String
    enum: ['amount']

  # Public: Custom options of coupon, used by couponType
  options:
    type: Object

  # Public: Apply log of coupon
  apply_log: [ApplyLog]

###
  Public: Create coupons.

  * `coupon` {Object}

    * `expired_at` {Date}
    * `available_times` {Number}
    * `type` {String}
    * `options` {Object}

  * `count` {Number}

  Return {Promise} resolve with array of {CouponCode}.
###
CouponCode.createCoupons = ({expired_at, available_times, type, options}, count) ->
  Q.all [1 .. count].map ->
    @create
      type: type
      code: utils.randomString 16
      options: options
      expired_at: expired_at
      available_times: available_times

###
  Public: Check availability for specified account.

  * `account` {Account}

  Return {Promise} resolve with {Boolean}.
###
CouponCode::validate = (account) ->
  if @available_times <= 0
    return Q false

  @populate().then ->
    @provider.validate account, @

###
  Public: Apply coupon for specified account.

  * `account` {Account}

  Return {Promise}.
###
CouponCode::apply = (account) ->
  if @available_times <= 0
    throw new Error 'coupon_unavailable'

  @populate().then ->
    @provider.apply(account, @).then =>
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
CouponCode::populate = ({req}) ->
  if @provider
    return Q @

  @provider = root.couponTypes.byName @type

  if @provider
    @provider.populateCoupon @, req: req
  else
    return Q.reject new Error 'provider_not_found'
