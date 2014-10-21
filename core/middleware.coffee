{_} = app.libs

authenticator = require './authenticator'

exports.csrf = ->
  csrf = app.libs.csrf()

  return (req, res, next) ->
    validator = ->
      unless req.method == 'GET'
        unless csrf.verify req.session.csrf_secret, req.body.csrf_token
          return res.status(403).send
            error: 'invalid_csrf_token'

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

exports.errorHandling = (req, res, next) ->
  res.error = (name, param = {}) ->
    param = _.extend param, error: name
    res.status(400).json param
  next()

exports.accountInfo = (req, res, next) ->
  req.inject [exports.parseToken], ->
    authenticator.authenticate req.token, (err, account) ->
      if account
        req.account = account
        res.locals.account = _.extend account,
          inGroup: (group_name) ->
            return group_name in account.groups

      next()

exports.requireAuthenticate = (req, res, next) ->
  req.inject [exports.accountInfo, exports.errorHandling], ->
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
