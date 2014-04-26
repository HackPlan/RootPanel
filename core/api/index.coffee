_ = require 'underscore'

mAccount = require '../model/account'

exports.bind = (app) ->
  for item in ['account', 'panel', 'ticket', 'admin']
    apiModule = require('./' + item)

    generateUrl = (name) ->
      if name[0] == '/'
        return name
      else
        return "/#{item}/#{name}/"

    buildGetController = (controller) ->
      return (req, res) ->
        if req.method == 'GET'
          req.body = req.query

        return controller req, res

    for name, controller of apiModule.get
      app.get generateUrl(name), buildGetController controller

    for name, controller of apiModule.post
      app.post generateUrl(name), controller

exports.accountRender = (callback) ->
  return (req, res) ->
    mAccount.authenticate req.token, (account) ->
      renderer = (name, data) ->
        res.render name, _.extend
          account: account
        , data ? {}

      callback req, res, account, renderer

exports.accountAuthenticateRender = (callback) ->
  return exports.accountRender (req, res, account, renderer) ->
    unless account
      return res.redirect '/account/login/'

    callback req, res, account, renderer

exports.accountAdminAuthenticateRender = (callback) ->
  return exports.accountAuthenticateRender (req, res, account, renderer) ->
    unless mAccount.inGroup account, 'root'
      return res.send 403

    callback req, res, account, renderer
