plugin = require './plugin'

mAccount = require './model/account'

exports.joinPlan = (account, plan, callback) ->
  mAccount.joinPlan account, plan, ->
    async.each config.plans[plan].services, (serviceName, callback) ->
      if serviceName in account.attribute.services
        return callback()

      mAccount.update _id: account._id,
        $addToSet:
          'attribute.services': serviceName
      , ->
        (plugin.get serviceName).service.enable account, ->
          callback()

    , ->
      callback()

exports.leavePlan = (account, plan, callback) ->
  mAccount.leavePlan account, plan, ->
    async.each config.plans[plan].services, (serviceName, callback) ->
      stillInService = do ->
        for item in _.without(account.attribute.plans, plan)
          if serviceName in config.plans[item].services
            return true

        return false

      if stillInService
        callback()
      else
        modifier =
          $pull:
            'attribute.services': serviceName
          $unset: {}

        modifier['$unset']["attribute.plugin.#{plan}"] = ''

        mAccount.update _id: account._id, modifier, ->
          (plugin.get serviceName).service.delete account, ->
            callback()

    , ->
      callback()
