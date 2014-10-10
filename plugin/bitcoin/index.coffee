jade = require 'jade'
path = require 'path'

bitcoin = require './bitcoin'

{mAccount} = app.models
{pluggable, config, utils} = app

module.exports = pluggable.createHelpers exports =
  name: 'bitcoin'
  type: 'extension'

exports.registerHook 'account.before_register',
  filter: (req, callback) ->
    bitcoin_secret = utils.randomSalt()

    bitcoin.genAddress bitcoin_secret, (address) ->
      req.account.pluggable.bitcoin =
        bitcoin_deposit_address: address
        bitcoin_secret: bitcoin_secret

      callback()

exports.registerHook 'billing.payment_methods',
  widget_generator: (req, callback) ->
    bitcoin.getExchangeRate config.billing.currency, (rate) ->
      exports.render 'payment_method', req,
        exchange_rate: rate
      , callback

exports.registerHook 'view.pay.display_payment_details',
  type: 'bitcoin'
  filter: (req, deposit_log, callback) ->
    callback exports.t(req) 'view.payment_details',
      order_id: deposit_log.payload.order_id
      short_order_id: deposit_log.payload.order_id[0 .. 40]

app.post '/bitcoin/coinbase_callback', (req, res) ->
  mAccount.findOne
    'pluggable.bitcoin.bitcoin_deposit_address': req.body.address
  , (err, account) ->
    unless account
      return res.send 400, 'Invalid Address'

    unless req.query.secret == account.pluggable.bitcoin.bitcoin_secret
      return res.send 400, 'Invalid Secret'

    bitcoin.getExchangeRate config.billing.currency, (rate) ->
      amount = req.body.amount / rate

      mAccount.incBalance account, 'deposit', amount,
        type: 'bitcoin'
        order_id: req.body.transaction.hash
      , ->
        res.send 'Success'
