module.exports = exports = app.db.collection 'balance_log'

sample =
  account_id: new ObjectID()
  type: 'deposit'
  amount: 10
  created_at: new Date()
  attribute:
    type: 'taobao'
    order_id: '560097131641814'

exports.create = (account, type, amount, attribute, callback) ->
  exports.insert
    account_id: account._id
    type: type
    amount: amount
    attribute: attribute
    created_at: new Date()
  , (err, result) ->
    callback err, result?[0]
