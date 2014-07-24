jade = require 'jade'
path = require 'path'
async = require 'async'
crypto = require 'crypto'

config = require '../../config'

mAccount = require '../../core/model/account'

mongodb = app.plugins.mongodb

mongodb.admin = app.db.admin()
mongodb.admin.authenticate config.mongodb.user, config.mongodb.password, ->
  mongodb.admin_users = app.db.db('admin').collection 'system.users'

module.exports =
  enable: (account, callback) ->
    md5 = crypto.createHash 'md5'
    md5.update "#{account.username}:mongo:#{mAccount.randomSalt()}"
    pwd = md5.digest 'hex'

    mongodb.admin_users.insert
      user: account.username
      pwd: pwd
      roles: []
    , (err, result) ->
      callback()

  delete: (account, callback) ->
    mongodb.admin_users.remove
      user: account.username
    , (err) ->
      mongodb.admin.listDatabases (err, result) ->
        dbs = _.filter result.databases, (i) ->
          return i.name[..account.username.length] == "#{account.username}_"

        async.each dbs, (db, callback) ->
          app.db.db(db.name).dropDatabase ->
            callback()
        , ->
          callback()

  widget: (account, callback) ->
    mongodb.admin.listDatabases (err, result) ->
      dbs = _.filter result.databases, (i) ->
        return i.name[..account.username.length] == "#{account.username}_"

      jade.renderFile path.join(__dirname, 'view/widget.jade'),
        account: account
        dbs: dbs
      , (err, html) ->
        callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
