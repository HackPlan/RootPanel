module.exports = exports = app.db.collection 'balance_log'

sample =
  account_id: new ObjectID()
  type: 'deposit'
  amount: 10
  created_at: new Date()
  payload:
    type: 'taobao'
    order_id: '560097131641814'

exports.create = (account, type, amount, payload, callback) ->
  exports.insert
    account_id: account._id
    type: type
    amount: amount
    payload: payload
    created_at: new Date()
  , (err, result) ->
    callback err, _.first result
