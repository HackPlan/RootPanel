async = require 'async'
crypto = require 'crypto'
request = require 'request'

config = require '../../config'

genAddress = (bitcoin_secret, callback) ->
  request 'https://coinbase.com/api/v1/account/generate_receive_address',
    method: 'POST'
    json:
      api_key: config.plugins.bitcoin.coinbase_api_key
      address:
        callback_url: "#{config.web.url}/bitcoin/coinbase_callback?secret=#{bitcoin_secret}"
  , (err, res, body) ->
    throw err if err
    callback body.address

module.exports = (db, callback) ->
  cAccount = db.collection 'accounts'

  cAccount.find().toArray (err, accounts) ->
    async.each accounts, (account, callback) ->
      bitcoin_secret = crypto.createHash('sha256').update(crypto.randomBytes(256)).digest('hex')

      genAddress bitcoin_secret, (address) ->
        cAccount.update {_id: account._id},
          $set:
            'attribute.bitcoin_deposit_address': address
            'attribute.bitcoin_secret': bitcoin_secret
        , callback

    , (err) ->
      console.log "[account.attribute.bitcoin_secret] update #{accounts.length} rows"
      callback err
