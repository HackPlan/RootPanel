_ = require 'underscore'
express = require 'express'
async = require 'async'

config = require '../config'
billing = require '../billing'
plugin = require '../plugin'
{renderAccount, errorHandling, requestAuthenticate} = require './middleware'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.get '/', requestAuthenticate, (req, res) ->
  billing.checkBilling req.account, (account) ->
    plans = []

    for name, info of config.plans
      plans.push _.extend info,
        name: name
        isEnable: name in req.account.attribute.plans

    account.attribute.remaining_time = Math.ceil(billing.calcRemainingTime(req.account) / 24)

    widgets = []
    async.map req.account.attribute.service, (item, callback) ->
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

      res.render 'panel',
        account: req.account
        plans: plans
        widgets: widgets
