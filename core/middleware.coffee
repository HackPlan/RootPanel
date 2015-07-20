expressSession = require 'express-session'
redisStore = require 'connect-redis'
moment = require 'moment-timezone'
crypto = require 'crypto'
csrf = require 'csrf'
path = require 'path'
fs = require 'fs'
_ = require 'lodash'

ViewHelpers = require './view-helpers'

{Account, SecurityLog, config} = root

builtInErrors = [
  EvalError, RangeError, ReferenceError
  SyntaxError, TypeError, URIError
]

exports.reqHelpers = (req, res, next) ->
  req.getTokenCode = ->
    if req.method == 'GET'
      return req.cookies?.token ? req.headers?['x-token'] ? req.headers?.token
    else
      return req.headers?['x-token'] ? req.headers?.token

  req.getClientInfo = ->
    return {
      ip: req.headers['x-real-ip'] ? req.ip
      ua: req.headers['user-agent']
    }

  req.getLanguage = ->
    if req.cookies?.language and req.cookies.language != 'auto'
      return req.cookies.language
    else
      return config.i18n.default_language

  req.getTimezone = ->
    return req.cookies?.timezone ? config.i18n.default_timezone

  req.getTranslator = ->
    return root.i18n.translator req

  req.getMoment = ->
    return moment.apply(arguments...).locale(req.getLanguage()).tz(req.getTimezone())

  req.createSecurityLog = (type, options, {account, token} = {}) ->
    SecurityLog.createLog (account ? req.account),
      token: token ? req.token
      options: options
      type: type

  res.createCookie = (name, value) ->
    res.cookie name, value,
      expires: new Date(Date.now() + config.web.cookie_time)

  res.createToken = (account = req.account) ->
    account.createToken('full_access', req.getClientInfo()).then (token) ->
      res.createCookie('token', token.code).json
        account_id: account._id
        token: token.code

      return token

  next()

exports.renderHelpers = (req, res, next) ->
  _.extend res.locals,
    _: _
    req: req
    res: res
    root: root
    config: config

    t: root.i18n.translator req

    plugin: (name) ->
      return root.plugins.byName name

    account: req.account

    site:
      name: req.getTranslator() config.web.name

    helpers: new ViewHelpers req, res

  res.render = (view, locals = {}) ->
    root.views.render view, _.defaults(locals, res.locals)
    .done (html) ->
      res.send html
    , (err) ->
      exports.errorHandling err, req, res, ->

  next()

exports.errorHandling = (err, req, res, next) ->
  if err.constructor in builtInErrors
    root.log err.stack

  res.status(400).json
    error: err.message

exports.session = ({redis}) ->
  session_key_path = path.join __dirname, '../session.key'

  unless fs.existsSync session_key_path
    fs.writeFileSync session_key_path, crypto.randomBytes(48).toString('hex')
    fs.chmodSync session_key_path, 0o750

  RedisStore = redisStore expressSession
  secret = fs.readFileSync(session_key_path).toString()

  return expressSession
    store: new RedisStore
      client: redis

    resave: false
    saveUninitialized: false
    secret: secret

exports.authenticate = (req, res, next) ->
  Account.authenticate(req.getTokenCode()).then ({token, account}) ->
    if token?.type == 'full_access'
      _.extend req,
        token: token
        account: account
  .finally next

exports.requireAuthenticate = (req, res, next) ->
  if req.account
    next()
  else if req.method == 'GET'
    res.redirect '/account/login'
  else
    next new Error 'auth failed'

exports.requireAdminAuthenticate = (req, res, next) ->
  if req.account?.isAdmin()
    next()
  else
    next new Error 'forbidden'
