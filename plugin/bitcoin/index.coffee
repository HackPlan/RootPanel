{jade, path} = app.libs
{Account} = app.models
{pluggable, config, utils} = app
{Plugin} = app.interfaces

bitcoin = require './bitcoin'

self = module.exports = new Plugin
  name: 'bitcoin'

  register_hooks:
    'app.ignore_csrf':
      path: '/bitcoin/coinbase_callback'

    'account.before_register':
      filter: (account, callback) ->
        bitcoin_secret = utils.randomSalt()

        bitcoin.genAddress bitcoin_secret, (address) ->
          account.pluggable.bitcoin =
            bitcoin_deposit_address: address
            bitcoin_secret: bitcoin_secret

          callback()

    'billing.payment_methods':
      type: 'bitcoin'

      widgetGenerator: (req, callback) ->
        bitcoin.getExchangeRate config.billing.currency, (rate) ->
          self.render 'payment_method', req,
            exchange_rate: rate
          , callback

      detailsMessage: (req, deposit_log, callback) ->
        callback self.getTranslator(req) 'view.payment_details',
          order_id: deposit_log.payload.order_id
          short_order_id: deposit_log.payload.order_id[... 40]

  initialize: ->
    app.express.post '/bitcoin/coinbase_callback', (req, res) ->
      Account.findOne
        'pluggable.bitcoin.bitcoin_deposit_address': req.body.address
      , (err, account) ->
        unless account
          return res.status(400).send 'Invalid Address'

        unless req.query.secret == account.pluggable.bitcoin.bitcoin_secret
          return res.status(400).send 'Invalid Secret'

        bitcoin.getExchangeRate config.billing.currency, (rate) ->
          amount = req.body.amount / rate

          account.incBalance amount, 'deposit',
            type: 'bitcoin'
            order_id: req.body.transaction.hash
          , ->
            res.send 'Success'
