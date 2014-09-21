express = require 'express'
async = require 'async'
_ = require 'underscore'

{requireAuthenticate, renderAccount} = require './../middleware'
{mAccount, mBalance} = app.models
{pluggable, billing, config} = app

module.exports = exports = express.Router()

exports.get '/pay', requireAuthenticate, renderAccount, (req, res) ->
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
        type:
          $in: ['billing', 'service_billing']
      ,
        sort:
          created_at: -1
        limit: LIMIT
      .toArray callback

  , (err, result) ->
    res.render 'panel/pay', _.extend result,
      nodes: _.values(config.nodes)

exports.get '/', requireAuthenticate, renderAccount, (req, res) ->
  billing.triggerBilling req.account, (account) ->
    view_data =
      account: account
      plans: []
      widgets_html: []

    for name, info of config.plans
      view_data.plans.push _.extend info,
        name: name
        is_enable: name in req.account.billing.plans

    async.map pluggable.selectHook(account, 'view.panel.widgets'), (hook, callback) ->
      hook.generator account, (html) ->
        callback null, html
    , (err, widgets_html) ->
      view_data.widgets_html = widgets_html

      res.render 'panel', view_data
