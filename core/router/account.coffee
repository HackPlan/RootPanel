{_, async, express} = app.libs
{requireAuthenticate} = app.middleware
{Account, SecurityLog, CouponCode} = app.models
{pluggable, config, utils, logger} = app

module.exports = exports = express.Router()

exports.get '/register', (req, res) ->
  res.render 'account/register'

exports.get '/login', (req, res) ->
  res.render 'account/login'

exports.get '/preferences', requireAuthenticate, (req, res) ->
  res.render 'account/preferences'

exports.get '/session_info/', (req, res) ->
  response =
    csrf_token: req.session.csrf_token

  if req.account
    _.extend response,
      id: account.id
      username: account.username

  res.json response

exports.post '/register', (req, res) ->
  Account.register req.body, (err, account) ->
    return res.error utils.pickErrorName err if err

    account.createToken 'full_access',
      ip: req.headers['x-real-ip']
      ua: req.headers['user-agent']
    , (err, token) ->
      logger.error err if err

      res.cookie 'token', token,
        expires: new Date(Date.now() + config.account.cookie_time)

      res.json
        id: account._id

exports.post '/login', (req, res) ->
  Account.search req.body.username, (account) ->
    unless account
      return res.error 'wrong_password'

    unless account.matchPassword req.body.password
      return res.error 'wrong_password'

    account.createToken 'full_access',
      ip: req.headers['x-real-ip']
      ua: req.headers['user-agent']
    , (err, token) ->
      logger.error err if err

      res.cookie 'token', token,
        expires: new Date(Date.now() + config.account.cookie_time)

      res.cookie 'language', account.preferences.language,
        expires: new Date(Date.now() + config.account.cookie_time)

      res.json
        id: account._id
        token: token

exports.post '/logout', requireAuthenticate, (req, res) ->
  authenticator.revokeToken req.token, ->
    SecurityLog.create req.account, 'revoke_token', req.token,
      revoke_ip: req.headers['x-real-ip']
      revoke_ua: req.headers['user-agent']
    , ->
    res.clearCookie 'token'
    res.json {}

exports.post '/update_password', requireAuthenticate, (req, res) ->
  unless Account.matchPassword req.account, req.body.old_password
    return res.error 'wrong_password'

  unless utils.rx.password.test req.body.password
    return res.error 'invalid_password'

  Account.updatePassword req.account, req.body.password, ->
    token = _.first _.where req.account.tokens,
      token: req.token

    SecurityLog.create req.account, 'update_password', req.token,
      token: _.omit(token, 'updated_at')
    , ->
      res.json {}

exports.post '/update_email', requireAuthenticate, (req, res) ->
  unless Account.matchPassword req.account, req.body.password
    return res.error 'wrong_password'

  unless utils.rx.email.test req.body.email
    return res.error 'invalid_email'

  Account.update {_id: req.account._id},
    $set:
      email: req.body.email
  , ->
    token = _.first _.where req.account.tokens,
      token: req.token

    SecurityLog.create req.account, 'update_email', req.token,
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

  Account.update _id: req.account._id, modifiers, ->
    SecurityLog.create req.account, 'update_settings', req.token,
      old_settings: _.pick.apply @, [req.account.settings].concat _.keys(req.body)
      settings: req.body
    , ->
      res.json {}

exports.get '/coupon_info', requireAuthenticate, (req, res) ->
  CouponCode.getCode req.body.code, (coupon_code) ->
    unless coupon_code
      return res.error 'code_not_exist'

    CouponCode.restrictCode req.account, coupon_code, (err) ->
      if err
        return res.error 'code_not_available'

      CouponCode.codeMessage coupon_code, (message) ->
        res.json
          message: message

exports.post '/apply_coupon', requireAuthenticate, (req, res) ->
  CouponCode.getCode req.body.code, (coupon_code) ->
    if coupon_code.expired and Date.now() > coupon_code.expired.getTime()
      return res.error 'code_expired'

    unless coupon_code.available_times > 0
      return res.error 'code_not_available'

    apply_log = _.find coupon_code.apply_log, (i) ->
      return i.account_id.toString() == req.account._id.toString()

    if apply_log
      return res.error 'already_used'

    CouponCode.applyCode req.account, coupon_code, ->
      res.json {}
