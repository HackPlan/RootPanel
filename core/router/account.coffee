express = require 'express'

config = require '../config'
utils = require './utils'
{renderAccount, errorHandling, requestAuthenticate} = require './middleware'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.get '/signup/', renderAccount, (req, res) ->
  res.render 'account/signup'

exports.get '/login/', renderAccount, (req, res) ->
  res.render 'account/login'

exports.post '/signup/', errorHandling, (req, res) ->
  unless utils.username.test req.body.username
    return res.error 'invalid_username'

  unless utils.email.test req.body.email
    return res.error 'invalid_email'

  unless utils.passwd.test req.body.passwd
    return res.error 'invalid_passwd'

  if req.body.username in config.account.invalid_username
    return res.error 'username_exist'

  mAccount.byUsername req.body.username, (account) ->
    if account
      return res.error 'username_exist'

    mAccount.byEmail req.body.email, (account) ->
      if account
        return res.error 'email_exist'

      mAccount.register req.body.username, req.body.email, req.body.passwd, (account) ->
        mAccount.createToken account, {}, (token)->
          res.cookie 'token', token,
            expires: new Date(Date.now() + config.account.cookie_time)

          res.json
            id: account._id

exports.post '/login/', errorHandling, (req, res) ->
  mAccount.byUsernameOrEmailOrId req.body.username, (account) ->
    unless account
      return res.error 'auth_failed'

    unless mAccount.matchPasswd account, req.body.passwd
      return res.error 'auth_failed'

    mAccount.createToken account, {}, (token) ->
      res.cookie 'token', token,
        expires: new Date(Date.now() + config.account.cookie_time)

      res.json
        id: account._id
        token: token

exports.post '/logout/', requestAuthenticate, (req, res) ->
  mAccount.removeToken req.token, ->
    res.clearCookie 'token'
    res.json {}

exports.post '/update_passwd/', requestAuthenticate, (req, res) ->
  unless mAccount.matchPasswd account, req.body.old_passwd
    return res.error 'auth_failed'

  unless req.body.new_passwd or not /^.+$/.test req.body.new_passwd
    return res.error 'invalid_passwd'

  mAccount.updatePasswd account, req.body.new_passwd, ->
    res.json {}
