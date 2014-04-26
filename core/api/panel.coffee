_ = require 'underscore'

config = require '../config'

mAccount = require '../model/account'

module.exports =
  get:
    '/': (req, res) ->
      res.redirect '/panel/'

    '/panel/': (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.redirect '/account/login/'

        plans = []

        for name, info of config.plans
          plans.push _.extend info,
            name: name
            isEnable: name in account.attribure.plans

        res.render 'panel',
          account: account
          plans: plans
