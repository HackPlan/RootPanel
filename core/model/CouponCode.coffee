_ = require 'underscore'

{utils, config, mabolo} = app
{ObjectID} = mabolo

ApplyLog = mabolo.model 'ApplyLog',
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  created_at:
    type: Date
    default: -> new Date()

CouponCode = mabolo.model 'CouponCode',
  code:
    required: true
    unique: true
    type: String

  expired_at:
    type: Date

  available_times:
    type: Number

  type:
    required: true
    type: String
    enum: ['amount']

  options:
    type: Object

  apply_log: [ApplyLog]

CouponCode.createCoupons = ({expired_at, available_times, type, options}, count) ->
  Q.all [1 .. count].map ->
    @create
      type: type
      code: utils.randomString 16
      options: options
      expired_at: expired_at
      available_times: available_times

CouponCode::validate = (account) ->
  if @available_times <= 0
    return Q false

  @populate().then ->
    @provider.validate account, @

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

CouponCode::populate = ({req}) ->
  @provider = rp.extends.coupons.byName @type

  if @provider
    @provider.populateCoupon @, req: req
  else
    throw new Error 'provider_not_found'
