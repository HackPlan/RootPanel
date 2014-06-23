request = require 'request'

config = require './../config'

mAccount = require './model/account'

exports.genAddress = (blockchain_secret, callback) ->
  callback_url = "#{config.web.url}/bitcoin/blockchain_callback?secret=#{blockchain_secret}"
  url = "https://blockchain.info/api/receive?method=create&address=#{config.bitcoin.forward_to}&callback=#{encodeURI(callback_url)}"

  request url, (err, res, body) ->
    body = JSON.parse body

    callback body.input_address

exports.getExchangeRate = (callback) ->
  app.redis.get 'rp:exchange_rate:cnybtc', (err, rate) ->
    if rate
      callback rate
    else
      request 'https://blockchain.info/ticker', (err, res, body) ->
        body = JSON.parse body
        rate = 1 / parseFloat(body['CNY']['15m'])

        app.redis.setex 'rp:exchange_rate:cnybtc', 60, rate, ->
          callback parseFloat rate

exports.doCallback = (data, callback) ->
  mAccount.byDepositAddress data.input_address, (err, account) ->
    unless data.secret == account.blockchain_secret
      return callback 'Invalid Secret'

    exports.getExchangeRate (rate) ->
      if data.confirmations > config.bitcoin.confirmations
        amount = parseFloat(data.value) / 100000000 / rate

        mAccount.incBalance account, 'deposit', amount,
          type: 'bitcoin'
          order_id: data.input_transaction_hash
        , ->
          callback '*OK*'
      else
        callback 'Confirmations Insufficient'
