async = require 'async'
_ = require 'underscore'

config = require '../../config'

module.exports = (db, callback) ->
  cAccount = db.collection 'accounts'
  cBalanceLog = db.collection 'balance_log'
  cFinancials = db.collection 'financials'
  cCoupon_Code = db.collection 'coupon_code'
  cCouponCode = db.collection 'couponcodes'
  cSecurity_Log = db.collection 'security_log'
  cSecurityLog = db.collection 'securitylogs'
  cTicket = db.collection 'tickets'

  async.series [
    (callback) ->
      console.log '[accounts] beginning'

      async.forever (callback) ->
        cAccount.findOne
          signup_at:
            $exist: true
        , (err, account) ->
          throw err if err

          unless account
            return callback 'finished'

          avatar_md5 = account.setting.avatar_url.match /[a-f0-9]{32}/

          account.setting.avatar_url = "//cdn.v2ex.com/gravatar/#{avatar_md5}"
          account.setting.language ?= 'auto'
          account.setting.timezone ?= config.i18n.default_timezone

          if account.attribute.plugin.shadowsocks
            account.attribute.plugin.shadowsocks.method = 'aes-256-cfb'

          account.attribute.plugin.bitcoin =
            bitcoin_deposit_address: account.attribure.bitcoin_deposit_address
            bitcoin_secret: account.attribure.bitcoin_secret

          for token in account.tokens
            token.type = 'full_access'
            token.payload = token.attribute
            delete token.attribute

          last_billing_at = {}

          for plan_name in account.attribute.plans
            last_billing_at[plan_name] = account.attribute.last_billing_at

          cAccount.update {_id: account._id},
            $set:
              email: account.email.toLowerCase()
              created_at: account.signup_at
              groups: account.group
              preferences: account.setting
              pluggable: account.attribute.plugin
              resources_limit: account.attribute.resources_limit
              tokens: tokens
              billing:
                services: account.attribute.services
                plans: account.attribute.plans
                balance: account.attribute.balance
                arrears_at: account.attribute.arrears_at
                last_billing_at: last_billing_at

            $unset:
              setting: true
              signup_at: true
              group: true

          , (err) ->
            throw err if err
            console.log "[accounts] updated #{account._id}(#{account.username})"
            callback()

      , callback

    (callback) ->
      console.log '[financials] beginning'

      async.forever (callback) ->
        cBalanceLog.findAndRemove {}, null, (err, balance_log) ->
          throw err if err

          unless balance_log
            return callback 'finished'

          if balance_log.type == 'service_billing'
            balance_log.type = 'usage_billing'

          cFinancials.insert
            account_id: balance_log.account_id
            type: balance_log.type
            amount: balance_log.amount
            created_at: balance_log.created_at
            payload: balance_log.attribute
          , (err) ->
            throw err if err
            console.log "[financials] created #{balance_log._id}}"
            callback()

      , ->
        db.dropCollection 'balance_log', callback

    (callback) ->
      console.log '[couponcodes] beginning'

      async.forever (callback) ->
        cCoupon_Code.findAndRemove {}, null, (err, coupon) ->
          throw err if err

          unless coupon
            return callback 'finished'

          cCouponCode.insert
            code: coupon.code
            expired: coupon.expired
            available_times: coupon.available_times
            type: coupon.type
            meta: coupon.meta
            apply_log: coupon.log
          , (err) ->
            throw err if err
            console.log "[couponcodes] created #{coupon._id}}"
            callback()

      , ->
        db.dropCollection 'coupon_code', callback

    (callback) ->
      console.log '[securitylogs] beginning'

      async.forever (callback) ->
        cSecurity_Log.findAndRemove {}, null, (err, security_log) ->
          throw err if err

          unless security_log
            return callback 'finished'

          if security_log.type == 'update_setting'
            security_log.type = 'update_preferences'

          token = security_log.attribute.token
          token.type ?= 'full_access'
          token.payload = token.attribute
          delete token.attribute

          cSecurityLog.insert
            account_id: security_log.account_id
            type: security_log.type
            created_at: security_log.created_at
            token: token
            payload: _.omit security_log.attribute, 'token'
          , (err) ->
            throw err if err
            console.log "[securitylogs] created #{security_log._id}}"
            callback()

      , ->
        db.dropCollection 'security_log', callback

    (callback) ->
      console.log '[tickets] beginning'

      async.forever (callback) ->
        cTicket.findOne
          replys:
            $exist: true
        , (err, ticket) ->
          throw err if err

          unless ticket
            return callback 'finished'

          for reply in ticket.replys
            reply.flags = reply.attribute
            delete reply.attribute

          cTicket.update {_id: ticket._id},
            $set:
              replies: ticket.replys
              flags: ticket.attribute

            $unset:
              replys: true
              attribute: true

          , (err) ->
            throw err if err
            console.log "[tickets] updated #{ticket._id}"
            callback()

      , callback

  ], callback
