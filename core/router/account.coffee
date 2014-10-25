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

      res.cookie 'token', token.token,
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

      res.cookie 'token', token.token,
        expires: new Date(Date.now() + config.account.cookie_time)

      res.cookie 'language', account.preferences.language,
        expires: new Date(Date.now() + config.account.cookie_time)

      res.json
        id: account._id
        token: token

exports.post '/logout', requireAuthenticate, (req, res) ->
  req.token.revoke ->
    req.account.createSecurityLog 'revoke_token', req.token,
      revoke_ip: req.headers['x-real-ip']
      revoke_ua: req.headers['user-agent']
    , (err) ->
      logger.error err if err

      res.clearCookie 'token'
      res.json {}

exports.post '/update_password', requireAuthenticate, (req, res) ->
  unless req.account.matchPassword req.body.original_password
    return res.error 'wrong_password'

  unless utils.rx.password.test req.body.password
    return res.error 'invalid_password'

  req.account.updatePassword req.body.password, ->
    req.account.createSecurityLog 'update_password', req.token, {}, (err) ->
      logger.error err if err

      res.json {}

exports.post '/update_email', requireAuthenticate, (req, res) ->
  unless account.matchPassword req.body.password
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
