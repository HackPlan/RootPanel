{request} = app.libs
{config, cache, logger} = app

# @param callback(address)
exports.genAddress = (bitcoin_secret, callback) ->
  if config.plugins.bitcoin.coinbase_api_key == 'coinbase-simple-api-key'
    app.deprecate 'Invalid coinbase-simple-api-key'
    return callback()

  request 'https://coinbase.com/api/v1/account/generate_receive_address',
    method: 'POST'
    json:
      api_key: config.plugins.bitcoin.coinbase_api_key
      address:
        callback_url: "#{config.web.url}/bitcoin/coinbase_callback?secret=#{bitcoin_secret}"
  , (err, res, body) ->
    logger.error if err
    callback body.address

# @param currency: CNY, USD, JPY etc.
# @param callback(rate)
exports.getExchangeRate = (currency, callback) ->
  cache.try
    key: 'bitcoin.getExchangeRate'
    currency: currency
  , (SETEX) ->
    request 'https://blockchain.info/ticker', (err, res, body) ->
      logger.error if err

      body = JSON.parse body
      rate = 1 / parseFloat(body[currency]['15m'])

      SETEX rate, 60

  , callback
