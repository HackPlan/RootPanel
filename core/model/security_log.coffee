module.exports = exports = app.db.collection 'security_log'

sample =
  account_id: new ObjectID()
  type: 'update_password/update_setting/update_email'
  created_at: new Date()
  attribute:
    token:
      token: 'b535a6cec7b73a60c53673f434686e04972ccafddb2a5477f066f30eded55a9b'
      created_at: Date()
      attribute:
        ip: '123.184.237.163'
        ua: 'Mozilla/5.0 (Intel Mac OS X) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.102'

exports.create = (account, type, attribute, callback) ->
  exports.insert
    account_id: account._id
    type: type
    attribute: attribute
    created_at: new Date()
  , (err, result) ->
    callback err, result?[0]
