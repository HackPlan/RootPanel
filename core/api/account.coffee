config = require '../config'
api = require './index'

mAccount = require '../model/account'

module.exports =
  get:
    signup: api.accountRender (req, res, account, renderer) ->
      renderer 'account/signup'

    login: api.accountRender (req, res, account, renderer) ->
      renderer 'account/login'

  post:
    signup: (req, res) ->
      unless /^[0-9a-z_]{3,23}$/.test req.body.username
        return res.json 400, error: 'invalid_username'

      unless /^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$/.test req.body.email
        return res.json 400, error: 'invalid_email'

      unless req.body.passwd or not /^.+$/.test req.body.passwd
        return res.json 400, error: 'invalid_passwd'

      if req.body.username in config.account.invalid_username
        return res.json 400, error: 'username_exist'

      mAccount.byUsername req.body.username, (account) ->
        if account
          return res.json 400, error: 'username_exist'

        mAccount.byEmail req.body.email, (account) ->
          if account
            return res.json 400, error: 'email_exist'

          mAccount.register req.body.username, req.body.email, req.body.passwd, (account) ->
            mAccount.createToken account, {}, (token)->
              res.cookie 'token', token,
                expires: new Date(Date.now() + config.account.cookie_time)

              return res.json
                id: account._id

    login: (req, res) ->
      mAccount.byUsernameOrEmailOrId req.body.username, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        unless mAccount.matchPasswd account, req.body.passwd
          return res.json 400, error: 'auth_failed'

        mAccount.createToken account, {}, (token) ->
          res.cookie 'token', token,
            expires: new Date(Date.now() + config.account.cookie_time)

          return res.json
            id: account._id
            token: token

    logout: (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        mAccount.removeToken req.token, ->
          res.clearCookie 'token'

          res.json {}

    update_passwd: (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        unless mAccount.matchPasswd account, req.body.old_passwd
          return res.json 400, error: 'auth_failed'

        unless req.body.new_passwd or not /^.+$/.test req.body.new_passwd
          return res.json 400, error: 'invalid_passwd'

        mAccount.updatePasswd account, req.body.new_passwd, ->
          res.json {}
