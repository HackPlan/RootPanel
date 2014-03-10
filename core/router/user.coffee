config = require '../config'

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

      unless /^[0-9a-z_]+$/.test data.username
        return res.json 400, error: 'invalid_username'

      unless /^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$/.test data.email
        return res.json 400, error: 'invalid_email'

      unless data.passwd or not /^.+$/.test data.passwd
        return res.json 400, error: 'invalid_passwd'

      User.byUsername data.username, (user) ->
        if user
          return res.json 400, error: 'username_exist'

        User.byEmail data.email, (user) ->
          if user
            return res.json 400, error: 'email_exist'

          User.register data.username, data.email, data.password, (user) ->
            user.createToken {}, (token)->
              res.cookie 'token', token,
                expires: new Date(Date.now() + config.user.cookieTime)

              return res.json
                id: user.data._id

    login: (req, res) ->
      data = req.body

      # @param callback(account)
      getAccount = (callback) ->
        User.byUsername data.username, (user) ->
          if user
            return callback user

          User.byEmail data.email, (user) ->
            return callback user

      getAccount (user) ->
        unless user
          return res.json 400, error: 'auth_failed'

        unless user.matchPasswd data.password
          return res.json 400, error: 'auth_failed'

        user.createToken {}, (token) ->
          res.cookie 'token', token,
            expires: new Date(Date.now() + config.user.cookieTime)

          return res.json
            id: user.data._id
            token: token

    logout: (req, res) ->
      User.authenticate req.token, (user) ->
        unless user
          return res.json 400, error: 'auth_failed'

        user.removeToken req.token, ->
          res.clearCookie 'token'

          res.json {}
