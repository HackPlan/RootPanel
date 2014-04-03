config = require '../config'

Account = require '../model/Account'

module.exports =
  get:
    signup: (req, res) ->
      Account.authenticate req.token, (account) ->
        res.render 'signup',
          account: account

    login: (req, res) ->
      Account.authenticate req.token, (account) ->
        res.render 'login',
          account: account

  post:
    signup: (req, res) ->
      data = req.body

      unless /^[0-9a-z_]+$/.test data.username
        return res.json 400, error: 'invalid_username'

      unless /^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$/.test data.email
        return res.json 400, error: 'invalid_email'

      unless data.passwd or not /^.+$/.test data.passwd
        return res.json 400, error: 'invalid_passwd'

      Account.byUsername data.username, (account) ->
        if account
          return res.json 400, error: 'username_exist'

        Account.byEmail data.email, (account) ->
          if account
            return res.json 400, error: 'email_exist'

          Account.register data.username, data.email, data.passwd, (account) ->
            account.createToken {}, (token)->
              res.cookie 'token', token,
                expires: new Date(Date.now() + config.account.cookieTime)

              return res.json
                id: account.data._id

    login: (req, res) ->
      data = req.body

      Account.byUsernameOrEmail data.username, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        unless account.matchPasswd data.passwd
          return res.json 400, error: 'auth_failed'

        account.createToken {}, (token) ->
          res.cookie 'token', token,
            expires: new Date(Date.now() + config.account.cookieTime)

          return res.json
            id: account.data._id
            token: token

    logout: (req, res) ->
      Account.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        account.removeToken req.token, ->
          res.clearCookie 'token'

          res.json {}
