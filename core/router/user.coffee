User = require '../model/User'

module.exports =
  get:
    signup: (req, res) ->
      res.render 'signup'

    login: (req, res) ->
      res.render 'login'

  post:
    signup: (req, res) ->
      data = req.body

      if not /^[0-9a-z_]+$/.test data.username
        return res.json 400, error: 'invalid_username'

      if not /^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$/.test data.email
        return res.json 400, error: 'invalid_email'

      if not data.passwd or not /^.+$/.test data.passwd
        return res.json 400, error: 'invalid_passwd'

      User.byUsername data.username, (account) ->
        if account
          return res.json 400, error: 'username_exist'

        User.byEmail data.email, (account) ->
          if account
            return res.json 400, error: 'email_exist'

          User.register data.username, data.email, data.password, (account) ->
            account.createToken {}, (token)->
              res.cookie 'token', token,
                expires: new Date(Date.now() + 30 * 24 * 3600 * 1000)

              return res.json
                id: account.data._id

    login: (req, res) ->
      data = req.body

      # @param callback(account)
      getAccount = (callback) ->
        User.byUsername data.username, (account) ->
          if account
            return callback account

          User.byEmail data.email, (account) ->
            return callback account

      getAccount (account) ->
        if not account
          return res.json 400, error: 'auth_failed'

        if not account.matchPasswd data.password
          return res.json 400, error: 'auth_failed'

        account.createToken {}, (token)->
          res.cookie 'token', token,
            expires: new Date(Date.now() + 30 * 24 * 3600 * 1000)

          return res.json
            id: account.data._id
            token: token
