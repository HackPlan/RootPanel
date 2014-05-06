_ = require 'underscore'
async  = require 'async'

config = require '../config'
api = require './index'
plugin = require '../plugin'
billing = require '../billing'

mAccount = require '../model/account'

module.exports =
  post:
    subscribe: (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        unless req.body.plan in config.plans
          return res.json 400, error: 'invaild_plan'

        if req.body.plan in account.attribute.plans
          return res.json 400, error: 'already_in_plan'

        billing.calcBiling account, (account) ->
          if account.attribute.balance < 0
            return res.json 400, error: 'insufficient_balance'

          mAccount.joinPlan account, req.body.plan, (account) ->
            async.each config.plans[req.body.plan].service, (serviceName, callback) ->
              if serviceName in account.attribute.service
                return callback()

              mAccount.uodate _id: account._id,
                $addToSet:
                  'attribute.service': serviceName
              , {}, ->
                (plugin.get serviceName).service.enable account, ->
                  callback()
            , ->
              return res.json {}

    unsubscribe: (req, res) ->
