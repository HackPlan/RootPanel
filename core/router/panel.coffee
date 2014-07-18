config = require '../../config'
billing = require '../billing'
plugin = require '../plugin'
bitcoin = require '../bitcoin'
{requestAuthenticate, renderAccount} = require './middleware'

mAccount = require '../model/account'
mBalance = require '../model/balance'

module.exports = exports = express.Router()

exports.get '/pay', requestAuthenticate, renderAccount, (req, res) ->
  LIMIT = 10

  async.parallel
    exchange_rate: (callback) ->
      bitcoin.getExchangeRate (rate) ->
        callback null, rate

    deposit_log: (callback) ->
      mBalance.find
        account_id: req.account._id
        type: 'deposit'
      ,
        sort:
          created_at: -1
        limit: LIMIT
      .toArray callback

    billing_log: (callback) ->
      mBalance.find
        account_id: req.account._id
        type: 'billing'
      ,
        sort:
          created_at: -1
        limit: LIMIT
      .toArray callback

  , (err, result) ->
    res.render 'panel/pay', result

exports.get '/', requestAuthenticate, (req, res) ->
  billing.checkBilling req.account, (account) ->
    plans = []

    for name, info of config.plans
      plans.push _.extend info,
        name: name
        isEnable: name in req.account.attribute.plans

    account.attribute.remaining_time = Math.ceil(billing.calcRemainingTime(account) / 24)

    async.map account.attribute.services, (item, callback) ->
      p = plugin.get item
      async.map (p.panel_widgets ? []), (widgetBuilder, callback) ->
        widgetBuilder account, (html) ->
          callback null,
            plugin: p
            html: html
      , (err, result) ->
        callback null, result
    , (err, result) ->
      widgets = []
      for item in result
        widgets = widgets.concat item

      res.render 'panel',
        account: account
        plans: plans
        widgets: widgets
