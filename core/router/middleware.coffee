_ = require 'underscore'

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
  res.error = (name, param) ->
    param = _.extend param, error: name
    res.json 400, param
  next()

exports.accountInfo = (req, res, next) ->
  req.inject [exports.parseToken], ->
    mAccount.authenticate req.token, (account) ->
      req.account = account
      next()

exports.renderAccount = (req, res, next) ->
  req.inject [exports.accountInfo], ->
    old_render = res.render
    res.render = (name, options = {} , fn) ->
      options = _.extend {account: req.account}, options
      old_render.call res, name, options, fn
    next()

exports.requestAuthenticate = (req, res, next) ->
  req.inject [exports.accountInfo, exports.errorHandling], ->
    if req.account
      next()
    else
      if req.method == 'GET'
        res.redirect '/account/login/'
      else
        res.error 'auth_failed'

exports.requestAdminAuthenticate = (req, res, next) ->
  req.inject [exports.requestAuthenticate], ->
    unless mAccount.inGroup req.account, 'root'
      if req.method == 'GET'
        return res.send 403
      else
        return res.error 'auth_failed'

    next()
