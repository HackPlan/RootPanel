module.exports = exports = app.db.buildModel 'coupon_code'

sample =
  code: 'PmlFH2hpziDmyqPX'
  expired: new Date()
  available_times: 2
  type: 'amount'
  meta:
    amount: 10
  log: [
    account_id: new ObjectID()
    created_at: new Date()
  ]

exports.type_meta =
  amount:
    message: (coupon_code) ->
      return "账户余额：#{coupon_code.meta.amount} CNY"

exports.codeMessage = (coupon_code) ->
  return exports.type_meta[coupon_code.type].message coupon_code

exports.getCode = (code, callback) ->
  exports.findOne
    code: code
  , (err, coupon_code) ->
    callback coupon_code