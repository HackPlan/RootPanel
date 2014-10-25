{pluggable} = app
{selectModelEnum} = pluggable
{_, ObjectId, mongoose} = app.libs

CouponCode = mongoose.Schema
  code:
    required: true
    type: String

  expired:
    type: Date
    default: null

  available_times:
    type: Number
    default: null

  type:
    required: true
    type: String
    enum: ['amount']

  meta:
    type: Object
    default: {}

  apply_log: [
    account_id:
      required: true
      type: ObjectId
      ref: 'Account'

    created_at:
      type: Date
      default: Date.now
  ]

exports.coupons_meta = coupons_meta =
  amount:
    validate: (account, coupon, callback) ->
      exports.findOne
        type: 'amount'
        $or: [
          'meta.category': coupon.meta.category
        ,
          'apply_log.account_id': account._id
        ]
      , (err, result) ->
        if result
          callback true
        else
          callback null

    message: (account, coupon, callback) ->
      callback "账户余额：#{coupon.meta.amount} CNY"

    apply: (account, coupon, callback) ->
      account.incBalance 'deposit', coupon.meta.amount,
        type: 'coupon'
        order_id: coupon.code
      , callback

# @param callback(err, coupons)
CouponCode.statics.createCodes = (template, count, callback) ->
  coupons = _.map _.range(0, count), ->
    return {
      code: utils.randomString 16
      expired: template.expired or null
      available_times: template.available_times
      type: template.type
      meta: template.meta
      apply_log: []
    }

  @create coupons, callback

CouponCode.methods.getMessage = (account, callback) ->
  coupons_meta[@type].message account, @, callback

CouponCode.methods.validate = (account, callback) ->
  coupons_meta[@type].validate account, @, callback

CouponCode.methods.apply = (account, callback) ->
  @update
    $inc:
      available_times: -1
    $push:
      log:
        account_id: account._id
        created_at: new Date()
  , (err) ->
    return callback err if err
    coupons_meta[@type].apply account, @, callback

_.extend app.models,
  CouponCode: mongoose.model 'CouponCode', CouponCode
