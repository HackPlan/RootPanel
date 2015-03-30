expressBunyanLogger = require 'express-bunyan-logger'
expressSession = require 'express-session'
redisStore = require 'connect-redis'
csrf = require 'csrf'

{config} = app
{_, path, fs, moment, crypto} = app.libs
{Account, SecurityLog} = app.models

exports.reqHelpers = (req, res, next) ->
  req.getCsrfToken = ->
    if req.headers['x-csrf-token']
      return req.headers['x-csrf-token']
    else
      return req.body.csrf_token

  req.getTokenCode = ->
    if req.headers['x-token']
      return req.headers['x-token']
    else
      return req.cookies.token

  req.getClientInfo = ->
    return {
      ip: req.headers['x-real-ip'] ? req.ip
      ua: req.headers['user-agent']
    }

  req.createSecurityLog = (type, payload, options) ->
    SecurityLog.createLog
      account: options?.account ? req.account
      token: options?.token ? req.token
      type: type
    , payload

  res.error = (status, name, param) ->
    unless _.isNumber status
      [status, name, param] = [400, status, name]

    if name?.message
      name = name.message

    if req.method in ['GET', 'HEAD', 'OPTIONS']
      res.status(status).send name.toString()
    else
      res.status(status).json _.extend {}, param,
        error: name.toString()

  res.createCookie = (name, value) ->
    res.cookie name, value,
      expires: new Date(Date.now() + config.account.cookie_time)

  res.createToken = (account = req.account) ->
    account.createToken('full_access', req.getClientInfo()).then (token) ->
      res.createCookie('token', token.code).json
        account_id: account._id
        token: token.code

      return token

  next()

exports.logger = ->
  return expressBunyanLogger
    genReqId: (req) -> req.sessionID
    parseUA: false
    logger: app.logger
    excludes: [
      'req', 'res', 'body', 'short-body', 'http-version',
      'incoming', 'req-headers', 'res-headers'
    ]

exports.session = ->
  session_key_path = path.join __dirname, '../session.key'

  unless fs.existsSync session_key_path
    fs.writeFileSync session_key_path, crypto.randomBytes(48).toString('hex')
    fs.chmodSync session_key_path, 0o750

  RedisStore = redisStore expressSession
  secret = fs.readFileSync(session_key_path).toString()

  return expressSession
    store: new RedisStore
      client: app.redis

    resave: false
    saveUninitialized: false
    secret: secret

exports.csrf = ->
  provider = csrf()

  return (req, res, next) ->
    validator = ->
      if req.path in app.getHooks('app.ignore_csrf', null, pluck: 'path')
        return next()

      if req.method in ['GET', 'HEAD', 'OPTIONS']
        return next()

      unless provider.verify req.session.csrf_secret, req.getCsrfToken()
        return res.error 403, 'invalid_csrf_token'

      next()

    if req.session.csrf_secret
      return validator()
    else
      provider.secret (err, secret) ->
        req.session.csrf_secret = secret
        req.session.csrf_token = provider.create secret

        validator()

exports.authenticate = (req, res, next) ->
  Account.authenticate(req.getTokenCode()).then ({token, account}) ->
    if token?.type == 'full_access'
      _.extend req,
        token: token
        account: account

  .finally next

exports.accountHelpers = (req, res, next) ->
  _.extend res,
    language: req.cookies.language ? config.i18n.default_language
    timezone: req.cookies.timezone ? config.i18n.default_timezone

    t: app.i18n.getTranslatorByReq req

    moment: ->
      if res.language and res.language != 'auto'
        return moment.apply(@, arguments).locale(res.language).tz(res.timezone)
      else if res.timezone
        return moment.apply(@, arguments).tz(res.timezone)
      else
        return moment.apply(@, arguments)

  _.extend req,
    res: res
    t: res.t

  _.extend res.locals,
    _: _

    app: app
    req: req
    res: res
    config: config

    account: req.account

    t: res.t
    moment: res.moment

    site_name: req.t(config.web.t_name)

    getHooks: (name, options) ->
      app.getHooks name, req.account, options

  next()

exports.requireAuthenticate = (req, res, next) ->
  if req.account
    next()
  else
    if req.method == 'GET'
      res.redirect '/account/login/'
    else
      res.error 403, 'auth_failed'

exports.requireAdminAuthenticate = (req, res, next) ->
  unless 'root' in req.account?.groups
    if req.method == 'GET'
      return res.status(403).end()
    else
      return res.error 'forbidden'

  next()

exports.requireInService = (service_name) ->
  return (req, res, next) ->
    exports.requireAuthenticate req, res, ->
      unless service_name in req.account.billing.services
        return res.error 'not_in_service'

      next()
