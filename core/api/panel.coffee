_ = require 'underscore'
async = require 'async'

config = require '../config'
api = require './index'
billing = require '../billing'
plugin = require '../plugin'

mAccount = require '../model/account'

module.exports =
  get:
    '/': (req, res) ->
      res.redirect '/panel/'

    '/panel/': api.accountAuthenticateRender (req, res, account, renderer) ->
      billing.checkBilling account, (account) ->
        plans = []

        for name, info of config.plans
          plans.push _.extend info,
            name: name
            isEnable: name in account.attribute.plans

        account.attribute.remaining_time = Math.ceil(billing.calcRemainingTime(account) / 24)

        widgets = []
        async.map account.attribute.service, (item, callback) ->
          p = plugin.get item
          async.map p.panel_widgets, (widgetBuilder, callback) ->
            widgetBuilder (html) ->
              callback null,
                plugin: p
                html: html
          , (err, result) ->
            callback null, result
        , (err, result) ->
          widgets = []
          for item in result
            widgets = widgets.concat item

          renderer 'panel',
            account: account
            plans: plans
            widgets: widgets
