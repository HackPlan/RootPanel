express = require 'express'
async = require 'async'
_ = require 'underscore'

{renderAccount, errorHandling, requireAuthenticate} = app.middleware
{mAccount, mSecurityLog, mCouponCode} = app.models
{pluggable, config, utils, authenticator} = app

module.exports = exports = express.Router()

exports.get '/register', renderAccount, (req, res) ->
  res.render 'account/register'

exports.get '/login', renderAccount, (req, res) ->
  res.render 'account/login'

exports.get '/setting', requireAuthenticate, renderAccount, (req, res) ->
  res.render 'account/setting'

exports.post '/register', errorHandling, (req, res) ->
  unless utils.rx.username.test req.body.username
    return res.error 'invalid_username'

  unless utils.rx.email.test req.body.email
    return res.error 'invalid_email'

  unless utils.rx.password.test req.body.password
    return res.error 'invalid_password'

  async.each pluggable.selectHook(req.account, 'account.username_filter'), (hook, callback) ->
    hook.filter account, (is_allow) ->
      if is_allow
        callback()
      else
        callback true

  , (not_allow) ->
    if not_allow
      return res.error 'username_exist'

    async.parallel
      username: (callback) ->
        mAccount.findOne
          username: req.body.username
        , (err, account) ->
          if account
            return res.error 'username_exist'

          callback account

      email: (callback) ->
        mAccount.findOne
          email: req.body.email
        , (err, account) ->
          if account
            return res.error 'email_exist'

          callback account

    , (err) ->
      return if err

      mAccount.register _.pick(req.body, 'username', 'email', 'password'), (account) ->
        authenticator.createToken account, 'full_access',
          ip: req.headers['x-real-ip']
          ua: req.headers['user-agent']
        , (token)->
          res.cookie 'token', token,
            expires: new Date(Date.now() + config.account.cookie_time)

          res.json
            id: account._id

exports.post '/login', errorHandling, (req, res) ->
  mAccount.search req.body.username, (err, account) ->
    unless account
      return res.error 'wrong_password'

    unless mAccount.matchPassword account, req.body.password
      return res.error 'wrong_password'

    authenticator.createToken account, 'full_access',
      ip: req.headers['x-real-ip']
      ua: req.headers['user-agent']
    , (token) ->
      res.cookie 'token', token,
        expires: new Date(Date.now() + config.account.cookie_time)

      res.cookie 'language', account.settings.language,
        expires: new Date(Date.now() + config.account.cookie_time)

      res.json
        id: account._id
        token: token

exports.post '/logout', requireAuthenticate, (req, res) ->
  authenticator.revokeToken req.token, ->
    mSecurityLog.create req.account, 'revoke_token', req.token,
      revoke_ip: req.headers['x-real-ip']
      revoke_ua: req.headers['user-agent']
    , ->
    res.clearCookie 'token'
    res.json {}

exports.post '/update_password', requireAuthenticate, (req, res) ->
  unless mAccount.matchPassword req.account, req.body.old_password
    return res.error 'wrong_password'

  unless utils.rx.password.test req.body.password
    return res.error 'invalid_password'

  mAccount.updatePassword req.account, req.body.password, ->
    token = _.first _.where req.account.tokens,
      token: req.token

    mSecurityLog.create req.account, 'update_password', req.token,
      token: _.omit(token, 'updated_at')
    , ->
      res.json {}

exports.post '/update_email', requireAuthenticate, (req, res) ->
  unless mAccount.matchPassword req.account, req.body.password
    return res.error 'wrong_password'

  unless utils.rx.email.test req.body.email
    return res.error 'invalid_email'

  mAccount.update {_id: req.account._id},
    $set:
      email: req.body.email
  , ->
    token = _.first _.where req.account.tokens,
      token: req.token

    mSecurityLog.create req.account, 'update_email', req.token,
      old_email: req.account.email
      email: req.body.email
    , ->
      res.json {}

exports.post '/update_preferences', requireAuthenticate, (req, res) ->
  modifiers =
    $set: {}

  for k, v of req.body
    unless k in ['qq', 'language']
      return res.error 'invalid_field'

    modifiers.$set["settings.#{k}"] = v

  mAccount.update _id: req.account._id, modifiers, ->
    mSecurityLog.create req.account, 'update_settings', req.token,
      old_settings: _.pick.apply @, [req.account.settings].concat _.keys(req.body)
      settings: req.body
    , ->
      res.json {}

exports.all '/coupon_info', requireAuthenticate, (req, res) ->
  mCouponCode.getCode req.body.code, (coupon_code) ->
    unless coupon_code
      return res.error 'code_not_exist'

    mCouponCode.restrictCode req.account, coupon_code, (err) ->
      if err
        return res.error 'code_not_available'

      mCouponCode.codeMessage coupon_code, (message) ->
        res.json
          message: message

exports.post '/use_coupon', requireAuthenticate, (req, res) ->
  mCouponCode.getCode req.body.code, (coupon_code) ->
    if coupon_code.expired and Date.now() > coupon_code.expired.getTime()
      return res.error 'code_expired'

    unless coupon_code.available_times > 0
      return res.error 'code_not_available'

    apply_log = _.find coupon_code.apply_log, (i) ->
      return i.account_id.toString() == req.account._id.toString()

    if apply_log
      return res.error 'already_used'

    mCouponCode.applyCode req.account, coupon_code, ->
      res.json {}
