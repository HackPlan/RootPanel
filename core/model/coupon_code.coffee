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
    enum: ['amount'].concat selectModelEnum 'CouponCode', 'type'

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

_.extend app.schemas,
  CouponCode: CouponCode

exports.type_meta =
  amount:
    restrict: (account, coupon_code, callback) ->
      exports.findOne
        type: 'amount'
        $or: [
          'meta.category': coupon_code.meta.category
        ,
          'apply_log.account_id': account._id
        ]
      , (err, result) ->
        if result
          callback true
        else
          callback null

    message: (coupon_code, callback) ->
      callback "账户余额：#{coupon_code.meta.amount} CNY"

    apply: (account, coupon_code, callback) ->
      mAccount.incBalance account, 'deposit', coupon_code.meta.amount,
        type: 'coupon'
        order_id: coupon_code.code
      , ->
        callback()

exports.codeMessage = (coupon_code, callback) ->
  exports.type_meta[coupon_code.type].message coupon_code, callback

exports.restrictCode = (account, coupon_code, callback) ->
  exports.type_meta[coupon_code.type].restrict account, coupon_code, callback

exports.createCodes = (coupon_code, count, callback) ->
  coupon_codes = _.map _.range(0, count), ->
    return {
      code: utils.randomString 16
      expired: coupon_code.expired or null
      available_times: coupon_code.available_times
      type: coupon_code.type
      meta: coupon_code.meta
      log: []
    }

  exports.insert coupon_codes, (err, coupon_codes) ->
    callback coupon_codes

exports.applyCode = (account, coupon_code, callback) ->
  exports.update {_id: coupon_code._id},
    $inc:
      available_times: -1
    $push:
      log:
        account_id: account._id
        created_at: new Date()
  , ->
    exports.type_meta[coupon_code.type].apply account, coupon_code, ->
      callback()

exports.getCode = (code, callback) ->
  exports.findOne
    code: code
  , (err, coupon_code) ->
    callback coupon_code
