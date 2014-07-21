request = require 'request'

config = require './../config'

exports.genAddress = (callback) ->
  request 'https://coinbase.com/api/v1/account/generate_receive_address',
    method: 'POST'
    json:
      api_key: config.bitcoin.coinbase_api_key
      address:
        callback_url: "#{config.web.url}/bitcoin/coinbase_callback"
  , (err, res, body) ->
    callback body.address

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
