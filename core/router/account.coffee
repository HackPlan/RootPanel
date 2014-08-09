config = require '../../config'
utils = require './utils'
{renderAccount, errorHandling, requireAuthenticate} = require './middleware'

mAccount = require '../model/account'
mSecurityLog = require '../model/security_log'
mCouponCode = require '../model/coupon_code'

module.exports = exports = express.Router()

exports.get '/signup', renderAccount, (req, res) ->
  res.render 'account/signup'

exports.get '/login', renderAccount, (req, res) ->
  res.render 'account/login'

exports.get '/setting', requireAuthenticate, renderAccount, (req, res) ->
  res.render 'account/setting'

exports.post '/signup', errorHandling, (req, res) ->
  unless utils.rx.username.test req.body.username
    return res.error 'invalid_username'

  unless utils.rx.email.test req.body.email
    return res.error 'invalid_email'

  unless utils.rx.password.test req.body.password
    return res.error 'invalid_password'

  require('../../plugin/linux/monitor').loadPasswd (passwd_cache) ->
    if req.body.username in _.values(passwd_cache)
      return res.error 'username_exist'

    mAccount.byUsername req.body.username, (err, account) ->
      if account
        return res.error 'username_exist'

      mAccount.byEmail req.body.email, (err, account) ->
        if account
          return res.error 'email_exist'

        mAccount.register req.body.username, req.body.email, req.body.password, (err, account) ->
          mAccount.createToken account,
            ip: req.headers['x-real-ip']
            ua: req.headers['user-agent']
          , (err, token)->
            res.cookie 'token', token,
              expires: new Date(Date.now() + config.account.cookie_time)

            res.json
              id: account._id

exports.post '/login', errorHandling, (req, res) ->
  mAccount.byUsernameOrEmailOrId req.body.username, (err, account) ->
    unless account
      return res.error 'wrong_password'

    unless mAccount.matchPassword account, req.body.password
      return res.error 'wrong_password'

    mAccount.createToken account,
      ip: req.headers['x-real-ip']
      ua: req.headers['user-agent']
    , (err, token) ->
      res.cookie 'token', token,
        expires: new Date(Date.now() + config.account.cookie_time)

      res.json
        id: account._id
        token: token

exports.post '/logout', requireAuthenticate, (req, res) ->
  mAccount.removeToken req.token, ->
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

    mSecurityLog.create req.account, 'update_password',
      token: _.omit(token, 'updated_at')
    , ->
      res.json {}

exports.post '/update_email', requireAuthenticate, (req, res) ->
  unless mAccount.matchPassword req.account, req.body.password
    return res.error 'wrong_password'

  unless utils.rx.email.test req.body.email
    return res.error 'invalid_email'

  mAccount.update _id: req.account._id,
    $set:
      email: req.body.email
  , ->
    token = _.first _.where req.account.tokens,
      token: req.token

    mSecurityLog.create req.account, 'update_email',
      old_email: req.account.email
      email: req.body.email
      token: _.omit(token, 'updated_at')
    , ->
      res.json {}

exports.post '/update_setting', requireAuthenticate, (req, res) ->
  unless req.body.name in ['qq']
    return res.error 'invalid_name'

  modifiers =
    $set: {}

  modifiers.$set["setting.#{req.body.name}"] = req.body.value

  mAccount.update _id: req.account._id, modifiers, ->
    token = _.first _.where req.account.tokens,
      token: req.token

    mSecurityLog.create req.account, 'update_setting',
      name: req.body.name
      old_value: req.account.setting[req.body.name]
      value: req.body.value
      token: _.omit(token, 'updated_at')
    , ->
      res.json {}

exports.all '/coupon_info', requireAuthenticate, (req, res) ->
  mCouponCode.getCode req.body.code, (coupon_code) ->
    unless coupon_code
      return res.error 'code_not_exist'

    res.json
      message: mCouponCode.codeMessage coupon_code

