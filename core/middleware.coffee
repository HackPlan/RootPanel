{_, expressSession, redisStore, path} = app.libs
{Account} = app.models

exports.errorHandling = ->
  return (req, res, next) ->
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

exports.parseToken = (req, res, next) ->
  if req.headers['x-token']
    req.token = req.headers['x-token']
  else
    req.token = req.cookies.token

  next()

exports.getParam = (req, res, next) ->
  if req.method == 'GET'
    req.body = req.query

  next()

exports.accountInfo = (req, res, next) ->
  req.inject [exports.parseToken], ->
    Account.authenticate req.token, (token, account) ->
      if token and token.type == 'full_access'
        res.locals.account = req.account = account

      next()

exports.requireAuthenticate = (req, res, next) ->
  if req.account
    next()
  else
    if req.method == 'GET'
      res.redirect '/account/login/'
    else
      res.error 'auth_failed'

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
      unless service_name in req.account.attribute.services
        return res.error 'not_in_service'

      next()

exports.constructObjectID = (fields = ['id']) ->
  return (req, res, next) ->
    for field in fields
      if req.body[field]
        req.body[field] = new ObjectID req.body[field]

    next()
