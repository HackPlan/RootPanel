{ObjectID} = require 'mongodb'
async = require 'async'
_ = require 'underscore'

module.exports = exports = app.db.collection 'notifications'

sample =
  account_id: ObjectID()
  group_name: 'root'
  created_at: Date()
  level: 'notice/event/log'
  type: 'payment_success'
  meta:
    amount: 10

exports.createNotice = (account, group_name, type, level, meta, callback) ->
  exports.insert
    account_id: account?._id ? null
    group_name: group_name ? null
    level: level
    type: type
    meta: meta
  , (err, result) ->
    callback _.first result
