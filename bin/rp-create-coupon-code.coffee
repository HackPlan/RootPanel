#!/usr/bin/env coffee

_ = require 'underscore'
async = require 'async'
{MongoClient} = require 'mongodb'

config = require '../config'

randomString = (length) ->
  char_map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

  result = ''

  result = _.map _.range(0, length), ->
    return char_map.charAt Math.floor(Math.random() * char_map.length)

  return result.join ''

{user, password, host, name} = config.mongodb
MongoClient.connect "mongodb://#{user}:#{password}@#{host}/#{name}", (err, db) ->
  mCouponCode = db.collection 'coupon_code'

  async.each _.range(0, 100), (i, callback) ->
    mCouponCode.insert
      code: randomString 16
      expired: new Date Date.now() + 365 * 24 * 3600 * 1000
      available_times: 1
      type: 'amount'
      meta:
        amount: 4
      log: []
    , (err, coupon_code) ->
      console.log _.first(coupon_code).code
      callback()
  , ->
    process.exit()
