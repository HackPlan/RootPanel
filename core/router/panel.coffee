config = require '../../config'
billing = require '../billing'
plugin = require '../plugin'
bitcoin = require '../bitcoin'
{requireAuthenticate, renderAccount} = require './middleware'

mAccount = require '../model/account'
mBalance = require '../model/balance'

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

exports.get '/', requireAuthenticate, (req, res) ->
  billing.checkBilling req.account, (account) ->
    result =
      account: account
      plans: []
      switch_buttons: []
      widgets: []
      script: []
      style: []

    for name, info of config.plans
      result.plans.push _.extend info,
        name: name
        is_enable: name in req.account.attribute.plans

    account.attribute.remaining_time = Math.ceil(billing.calcRemainingTime(account) / 24)

    async.eachSeries account.attribute.services, (service_name, callback) ->
      service_plugin = plugin.get service_name

      if service_plugin.switch
        result.switch_buttons.push service_name

      if service_plugin.panel?.script
        result.script.push "/plugin/#{service_name}#{service_plugin.panel.script}"

      if service_plugin.panel?.style
        result.style.push "/plugin/#{service_name}#{service_plugin.panel.style}"

      async.parallel [
        (callback) ->
          unless service_plugin.panel?.widget
            return callback()

          service_plugin.panel.widget account, (html) ->
            result.widgets.push
              plugin: service_plugin
              html: html
            callback()

        (callback) ->
          if service_plugin.switch_status
            service_plugin.switch_status account, (is_enable) ->
              account.attribute.plugin[service_name] ?= {}
              account.attribute.plugin[service_name].is_enable = is_enable
              callback()
          else
            callback()
      ], callback

    , ->
      res.render 'panel', result
