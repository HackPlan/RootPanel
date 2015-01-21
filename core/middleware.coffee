expressBunyanLogger = require 'express-bunyan-logger'
expressSession = require 'express-session'
redisStore = require 'connect-redis'

{config} = app
{_, path, fs, moment, crypto} = app.libs
{Account} = app.models

exports.errorHandling = (req, res, next) ->
  res.error = (status, name, param) ->
    unless _.isNumber status
      [status, name, param] = [400, status, name]

    param ?= {}

    if req.method in ['GET', 'HEAD', 'OPTIONS']
      res.status(status).send name.toString()
    else
      res.status(status).json _.extend param,
        error: name.toString()

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
  csrf = app.libs.csrf()

  return (req, res, next) ->
    if req.path in _.pluck app.pluggable.selectHooks('app.ignore_csrf'), 'path'
      return next()

    csrf_token = do ->
      if req.headers['x-csrf-token']
        return req.headers['x-csrf-token']
      else
        return req.body.csrf_token

    validator = ->
      unless req.method in ['GET', 'HEAD', 'OPTIONS']
        unless csrf.verify req.session.csrf_secret, csrf_token
          return res.error 'invalid_csrf_token', null, 403

      next()

    if req.session.csrf_secret
      return validator()
    else
      csrf.secret (err, secret) ->
        req.session.csrf_secret = secret
        req.session.csrf_token = csrf.create secret

        validator()

exports.authenticate = (req, res, next) ->
  token_code = do ->
    if req.headers['x-token']
      return req.headers['x-token']
    else
      return req.cookies.token

  unless token_code
    return next()

  Account.authenticate token_code, (token, account) ->
    if token and token.type == 'full_access'
      req.token = token
      req.account = account

    next()

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

    selectHooks: app.pluggable.selectHooks

  next()

exports.requireAuthenticate = (req, res, next) ->
  if req.account
    next()
  else
    if req.method == 'GET'
      res.redirect '/account/login/'
    else
      res.error 'auth_failed', null, 403

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
