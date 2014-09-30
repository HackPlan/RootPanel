jade = require 'jade'
path = require 'path'

bitcoin = require './bitcoin'

{mAccount} = app.models
{pluggable, config} = app

module.exports = pluggable.createHelpers exports =
  name: 'bitcoin'
  type: 'extension'

exports.registerHook 'account.before_register',
  filter: (account, callback) ->
    bitcoin_secret = exports.randomSalt()

    bitcoin.genAddress bitcoin_secret, (address) ->
      account.pluggable.bitcoin =
        bitcoin_deposit_address: address
        bitcoin_secret: bitcoin_secret

      callback()

exports.registerHook 'billing.payment_method',
  widget_generator: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/payment_method.jade'),
      account: account
    , (err, html) ->
      callback html

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
