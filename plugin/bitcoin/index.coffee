request = require 'request'

{mAccount} = app.models
{pluggable, redis, config} = app

module.exports =
  name: 'bitcoin'
  type: 'extension'

# @param callback(address)
genAddress = (bitcoin_secret, callback) ->
  request 'https://coinbase.com/api/v1/account/generate_receive_address',
    method: 'POST'
    json:
      api_key: config.bitcoin.coinbase_api_key
      address:
        callback_url: "#{config.web.url}/bitcoin/coinbase_callback?secret=#{bitcoin_secret}"
  , (err, res, body) ->
    throw err if err
    callback body.address

# @param currency: CNY, USD, JPY
# @param callback(rate)
getExchangeRate = (currency, callback) ->
  REDIS_KEY = "#{config.redis.prefix}:[bitcoin.getExchangeRate]:#{currency}"

  redis.get REDIS_KEY, (err, rate) ->
    if rate
      callback rate
    else
      request 'https://blockchain.info/ticker', (err, res, body) ->
        throw err if err

        body = JSON.parse body
        rate = 1 / parseFloat(body[currency]['15m'])

        app.redis.setex REDIS_KEY, 60, rate, ->
          callback parseFloat rate

pluggable.hooks.account.before_register.psuh (account, callback) ->
  bitcoin_secret = exports.randomSalt()

  genAddress bitcoin_secret, (address) ->
    account.pluggable.bitcoin =
      bitcoin_deposit_address: address
      bitcoin_secret: bitcoin_secret

    callback()

app.post '/bitcoin/coinbase_callback', (req, res) ->
  mAccount.findOne
    'pluggable.bitcoin.bitcoin_deposit_address': req.body.address
  , (err, account) ->
    unless account
      return res.send 400, 'Invalid Address'

    unless req.query.secret == account.pluggable.bitcoin.bitcoin_secret
      return res.send 400, 'Invalid Secret'

    getExchangeRate config.billing.currency, (rate) ->
      amount = req.body.amount / rate

      mAccount.incBalance account, 'deposit', amount,
        type: 'bitcoin'
        order_id: req.body.transaction.hash
      , ->
        res.send 'Success'
