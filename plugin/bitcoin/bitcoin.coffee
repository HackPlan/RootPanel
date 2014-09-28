request = require 'request'

{config, cache} = app

# @param callback(address)
exports.genAddress = (bitcoin_secret, callback) ->
  request 'https://coinbase.com/api/v1/account/generate_receive_address',
    method: 'POST'
    json:
      api_key: config.plugins.bitcoin.coinbase_api_key
      address:
        callback_url: "#{config.web.url}/bitcoin/coinbase_callback?secret=#{bitcoin_secret}"
  , (err, res, body) ->
    throw err if err

    callback body.address

# @param currency: CNY, USD, JPY etc.
# @param callback(rate)
exports.getExchangeRate = (currency, callback) ->
  cache.try 'bitcoin.getExchangeRate',
    param: currency: currency
    command: cache.SETEX 60
  , (callback) ->
    request 'https://blockchain.info/ticker', (err, res, body) ->
      throw err if err

      body = JSON.parse body
      rate = 1 / parseFloat(body[currency]['15m'])

      callback parseFloat rate
  , (rate) ->
    callback rate
