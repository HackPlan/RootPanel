{config} = app
{_, expressSession, redisStore, path, fs} = app.libs
{Account} = app.models

exports.errorHandling = (req, res, next) ->
  res.error = (name, param = {}, status = 400) ->
    res.status(status).json _.extend param,
      error: name

  next()

exports.session = ->
  RedisStore = redisStore expressSession
  secret = fs.readFileSync(path.join __dirname, '../session.key').toString()

  return expressSession
    store: new RedisStore
      client: app.redis

    resave: false
    saveUninitialized: false
    secret: secret

exports.csrf = ->
  csrf = app.libs.csrf()

  return (req, res, next) ->
    validator = ->
      unless req.method == 'GET'
        unless csrf.verify req.session.csrf_secret, req.body.csrf_token
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
  token_field = do ->
    if req.headers['x-token']
      return req.headers['x-token']
    else
      return req.cookies.token

  unless token_field
    return next()

  Account.authenticate token_field, (token, account) ->
    if token and token.type == 'full_access'
      req.token = token
      req.account = account

    next()

exports.accountHelpers = (req, res, next) ->
  _.extend req,
    res: res

  _.extend res,
    language: req.cookies.language ? config.i18n.default_language
    timezone: req.cookies.timezone ? config.i18n.default_timezone

    t: app.i18n.getTranslator req

    moment: ->
      return moment.apply(@, arguments).locale(res.language).tz(res.timezone)

  _.extend res.locals,
    app: app
    req: req
    res: res
    config: config

    t: res.t
    moment: res.moment

    selectHook: (name) ->
      return app.pluggable.selectHook req.account, name

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
  req.inject [exports.requireAuthenticate], ->
    unless 'root' in req.account.groups
      if req.method == 'GET'
        return res.status(403).end()
      else
        return res.error 'forbidden'

    next()

exports.requireInService = (service_name) ->
  return (req, res, next) ->
    req.inject [exports.requireAuthenticate], ->
      unless service_name in req.account.billing.services
        return res.error 'not_in_service'

      next()
