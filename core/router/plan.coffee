_ = require 'underscore'
async  = require 'async'
express = require 'express'

config = require '../config'
plugin = require '../plugin'
billing = require '../billing'
{requestAuthenticate} = require './middleware'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.post '/subscribe', requestAuthenticate, (req, res) ->
  unless req.body.plan in _.keys(config.plans)
    return res.error 'invaild_plan'

  if req.body.plan in req.account.attribute.plans
    return res.error 'already_in_plan'

  billing.calcBilling req.account, true, (account) ->
    if account.attribute.balance < 0
      return res.error 'insufficient_balance'

    mAccount.joinPlan account, req.body.plan, ->
      async.each config.plans[req.body.plan].services, (serviceName, callback) ->
        if serviceName in account.attribute.services
          return callback()

        mAccount.update _id: account._id,
          $addToSet:
            'attribute.services': serviceName
        , {}, ->
          if config.debug.mock_test
            return callback()

          (plugin.get serviceName).service.enable account, ->
            callback()
      , ->
        return res.json {}

exports.post '/unsubscribe', requestAuthenticate, (req, res) ->
  unless req.body.plan in req.account.attribute.plans
    return res.error 'not_in_plan'

  billing.calcBilling req.account, true, (account) ->
    mAccount.leavePlan account, req.body.plan, ->
      async.each config.plans[req.body.plan].services, (serviceName, callback) ->
        stillInService = do ->
          for item in _.without(account.attribute.plans, req.body.plan)
            if serviceName in config.plans[req.body.plan].services
              return true

          return false

        if stillInService
          callback()
        else
          mAccount.update _id: account._id,
            $pull:
              'attribute.services': serviceName
          , {}, ->
            if config.debug.mock_test
              return callback()

            (plugin.get serviceName).service.delete account, ->
              callback()
      , ->
        return res.json {}
