_ = require 'underscore'

config = require '../config'
api = require './index'

mAccount = require '../model/account'

module.exports =
  get:
    '/': (req, res) ->
      res.redirect '/panel/'

    '/panel/': api.accountAuthenticateRender (req, res, account, renderer) ->
      plans = []

      for name, info of config.plans
        plans.push _.extend info,
          name: name
          isEnable: name in account.attribute.plans

      renderer 'panel',
        plans: plans
