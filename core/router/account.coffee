{_, express} = app.libs
{requireAuthenticate} = app.middleware
{Account, SecurityLog, CouponCode} = app.models
{config, utils, logger, i18n} = app

module.exports = exports = express.Router()

exports.get '/register', (req, res) ->
  res.render 'account/register'

exports.get '/login', (req, res) ->
  res.render 'account/login'

exports.get '/locale/:language?', (req, res) ->
  if req.params['language']
    req.cookies['language'] = req.params['language']

  res.json i18n.pickClientLocale i18n.getLanguagesByReq req

exports.get '/preferences', requireAuthenticate, (req, res) ->
  res.render 'account/preferences'

exports.get '/session_info/', (req, res) ->
  response =
    csrf_token: req.session.csrf_token

  if req.account
    _.extend response,
      id: req.account.id
      username: req.account.username
      preferences: req.account.preferences

  res.json response

exports.post '/register', (req, res) ->
  Account.register(req.body).then (account) ->
    res.createToken account
  .catch res.error

exports.post '/login', (req, res) ->
  Account.search(req.body.username).then (account) ->
    if account?.matchPassword req.body.password
      throw new Error 'wrong_password'

    res.createCookie 'language', account.preferences.language

    res.createToken(account).then (token) ->
      req.createSecurityLog 'login', {},
        account: account
        token: token

  .catch res.error

exports.post '/logout', requireAuthenticate, (req, res) ->
  req.token.revoke().then ->
    req.createSecurityLog('revoke_token').then ->
      res.clearCookie('token').sendStatus 204
  .catch res.error

exports.post '/update_password', requireAuthenticate, (req, res) ->
  Q().then ->
    unless req.account.matchPassword req.body.original_password
      throw new Error 'wrong_password'

    unless utils.rx.password.test req.body.password
      throw new Error 'invalid_password'

    req.account.setPassword(req.body.password).then ->
      req.createSecurityLog 'update_password'

  .catch res.error

exports.post '/update_email', requireAuthenticate, (req, res) ->
  unless req.account.matchPassword req.body.password
    return res.error 'wrong_password'

  unless utils.rx.email.test req.body.email
    return res.error 'invalid_email'

  req.account.email = req.body.email

  req.account.save (err) ->
    logger.error err if err

    req.account.createSecurityLog 'update_email', req.token,
      original_email: req.account.email
      email: req.body.email
    , (err) ->
      logger.error err if err

      res.json {}

exports.post '/update_preferences', requireAuthenticate, (req, res) ->
  req.body = _.omit req.body, 'csrf_token'

  for k, v of req.body
    if k in ['qq', 'language', 'timezone']
      req.account.preferences[k] = v
      req.account.markModified "preferences.#{k}"
    else
      return res.error 'invalid_field'

  req.account.save (err) ->
    logger.error err if err

    req.account.createSecurityLog 'update_preferences', req.token,
      original_preferences: _.pick.apply @, [req.account.preferences].concat _.keys(req.body)
      preferences: req.body
    , (err) ->
      logger.error err if err

      res.json {}

exports.use do ->
  router = new express.Router()

  router.use requireAuthenticate

  router.get '/info', (req, res) ->
    CouponCode.findOne
      code: req.query.code
    , (err, coupon) ->
      unless coupon
        return res.error 'code_not_exist'

      coupon.validateCode req.account, (is_available) ->
        unless is_available
          return res.error 'code_not_available'

        coupon.getMessage req, (message) ->
          res.json
            message: message

  router.post '/apply', (req, res) ->
    CouponCode.findOne
      code: req.body.code
    , (err, coupon) ->
      unless coupon
        return res.error 'code_not_exist'

      if coupon.expired and Date.now() > coupon.expired.getTime()
        return res.error 'code_expired'

      if coupon.available_times and coupon.available_times < 0
        return res.error 'code_not_available'

      coupon.validateCode req.account, (is_available) ->
        unless is_available
          return res.error 'code_not_available'

        coupon.applyCode req.account, ->
          res.json {}
