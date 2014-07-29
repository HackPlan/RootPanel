mAccount = require '../model/account'

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
    mAccount.authenticate req.token, (err, account) ->
      req.account = account
      next()

exports.renderAccount = (req, res, next) ->
  req.inject [exports.accountInfo], ->
    old_render = res.render
    res.render = (name, options = {} , fn) ->
      options = _.extend {account: req.account}, options
      old_render.call res, name, options, fn
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
    unless mAccount.inGroup req.account, 'root'
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