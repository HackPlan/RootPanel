{ObjectID} = require 'mongodb'
_ = require 'underscore'

module.exports = exports = app.db.collection 'coupon_codes'

mAccount = require './account'

utils = require '../utils'

sample =
  code: 'PmlFH2hpziDmyqPX'
  expired: new Date()
  available_times: 2
  type: 'amount'
  meta:
    amount: 10
    category: '2014.9.20'
  apply_log: [
    account_id: new ObjectID()
    created_at: new Date()
  ]

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
