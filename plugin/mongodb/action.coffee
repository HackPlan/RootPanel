crypto = require 'crypto'

{assertInService} = require '../../core/router/middleware'

mongodb = app.plugins.mongodb

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

exports.use assertInService 'mongodb'

exports.post '/update_password', (req, res) ->
  unless req.body.password or /^[A-Za-z0-9\-_]+$/.test req.body.password
    return res.error 'invalid_password'

  md5 = crypto.createHash 'md5'
  md5.update "#{req.account.username}:mongo:#{req.body.password}"
  pwd = md5.digest 'hex'

  mongodb.admin_users.update user: req.account.username,
    $set:
      pwd: pwd
  , (err, result) ->
    mongodb.admin.listDatabases (err, result) ->
      dbs = _.filter result.databases, (i) ->
        return i.name[..req.account.username.length] == "#{req.account.username}_"

      async.each dbs, (db, callback) ->
        db_users = app.db.db(db.name).collection 'system.users'
        db_users.update user: req.account.username,
          $set:
            pwd: pwd
        , ->
          callback()
      , ->
        res.json {}

exports.post '/create_database', (req, res) ->
  unless req.body.name[..req.account.username.length] == "#{req.account.username}_"
    return res.error 'invalid_name'

  unless /^[A-Za-z0-9_]+$/.test req.body.name
    return res.error 'invalid_name'

  mongodb.admin_users.findOne
    user: req.account.username
  , (err, result) ->
    db_users = app.db.db(req.body.name).collection 'system.users'
    db_users.insert
      user: req.account.username
      pwd: result.pwd
      roles: ['readWrite', 'dbAdmin']
    , (err) ->
      res.json {}

exports.post '/delete_database', (req, res) ->
  unless req.body.name[..req.account.username.length] == "#{req.account.username}_"
    return res.error 'invalid_name'

  unless /^[A-Za-z0-9_]+$/.test req.body.name
    return res.error 'invalid_name'

  app.db.db(req.body.name).dropDatabase ->
    res.json {}
