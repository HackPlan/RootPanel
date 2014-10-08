express = require 'express'
async = require 'async'
_ = require 'underscore'

{requireAuthenticate, renderAccount} = require './../middleware'
{mAccount, mBalanceLog} = app.models
{pluggable, billing, config} = app

module.exports = exports = express.Router()

exports.get '/pay', requireAuthenticate, renderAccount, (req, res) ->
  LIMIT = 10

  async.parallel
    payment_methods: (callback) ->
      async.map pluggable.selectHook(req.account, 'billing.payment_methods'), (hook, callback) ->
        hook.widget_generator req, (html) ->
          callback null, html
      , callback

    deposit_log: (callback) ->
      mBalanceLog.find
        account_id: req.account._id
        type: 'deposit'
      ,
        sort:
          created_at: -1
        limit: LIMIT
      .toArray (err, deposit_logs) ->
        async.each deposit_logs, (deposit_log, callback) ->
          matched_hook = _.find pluggable.selectHook(req.account, 'view.pay.display_payment_details'), (hook) ->
            return hook?.type == deposit_log.payload.type

          unless matched_hook
            return callback()

          matched_hook.filter req, deposit_log, (payment_details) ->
            deposit_log.payment_details = payment_details

            callback()

        , ->
          callback null, deposit_logs

    billing_log: (callback) ->
      mBalanceLog.find
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
      hook.generator req, (html) ->
        callback null, html
    , (err, widgets_html) ->
      view_data.widgets_html = widgets_html

      res.render 'panel', view_data
