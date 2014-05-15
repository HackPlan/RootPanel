_ = require 'underscore'

config = require '../config'
api = require './index'
billing = require '../billing'

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

        renderer 'panel',
          account: account
          plans: plans
