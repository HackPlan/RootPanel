_ = require 'underscore'
async = require 'async'

mAccount = require '../model/account'

inject = (dependency, req, res, callback) ->
  async.eachSeries dependency, (item, callback) ->
    item req, res, callback
  , callback

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
  inject [exports.parseToken], req, res, ->
    mAccount.authenticate req.token, (account) ->
      req.account = account
      next()

exports.renderAccount = (req, res, next) ->
  inject [exports.accountInfo], req, res, ->
    old_render = res.render
    res.render = (name, options = {} , fn) ->
      options = _.extend {account: req.account}, options
      old_render.call res, name, options, fn
    next()

exports.requestAuthenticate = (req, res, next) ->
  inject [exports.accountInfo, exports.errorHandling], req, res, ->
    if req.account
      next()
    else
      if req.method == 'GET'
        res.redirect '/account/login/'
      else
        res.error 'auth_failed'

exports.requestAdminAuthenticate = (req, res, next) ->
  inject [exports.accountInfo, exports.errorHandling], req, res, ->
    unless req.account
      if req.method == 'GET'
        return res.redirect '/account/login/'
      else
        return res.error 'auth_failed'

    unless mAccount.inGroup req.account, 'root'
      if req.method == 'GET'
        return res.send 403
      else
        return res.error 'auth_failed'

    next()
