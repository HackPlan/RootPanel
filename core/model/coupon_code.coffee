{ObjectID} = require 'mongodb'

mAccount = require './account'

module.exports = exports = app.db.collection 'coupon_code'

sample =
  code: 'PmlFH2hpziDmyqPX'
  expired: new Date()
  available_times: 2
  type: 'amount'
  meta:
    amount: 10
  apply_log: [
    account_id: new ObjectID()
    created_at: new Date()
  ]

exports.type_meta =
  amount:
    message: (coupon_code) ->
      return "账户余额：#{coupon_code.meta.amount} CNY"

    apply: (account, coupon_code, callback) ->
      mAccount.incBalance account, 'deposit', coupon_code.meta.amount,
        type: 'coupon'
        order_id: coupon_code.code
      , ->
        callback()

exports.codeMessage = (coupon_code) ->
  return exports.type_meta[coupon_code.type].message coupon_code

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
