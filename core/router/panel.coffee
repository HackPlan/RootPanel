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

    switch_buttons = []
    panel_script = []

    async.map account.attribute.services, (service_name, callback) ->
      service_plugin = plugin.get service_name

      if service_plugin.switch
        switch_buttons.push service_name

      if service_plugin.panel_script
        for item in service_plugin.panel_script
          panel_script.push "/plugin/#{service_name}#{item}"

      async.parallel
        widgets: (callback) ->
          async.map (service_plugin.panel_widgets ? []), (widgetBuilder, callback) ->
            widgetBuilder account, (html) ->
              callback null,
                plugin: service_plugin
                html: html
          , (err, result) ->
            callback null, result

        switch_status: (callback) ->
          if service_plugin.switch_status
            service_plugin.switch_status account, (is_enable) ->
              account.attribute.plugin[service_name] ?= {}
              account.attribute.plugin[service_name].is_enable = is_enable
              callback()
          else
            callback()

      , callback
    , (err, result) ->
      widgets = []

      for item in result
        widgets = widgets.concat item.widgets

      res.render 'panel',
        switch_buttons: switch_buttons
        panel_script: panel_script
        plugin: plugin
        account: account
        plans: plans
        widgets: widgets
