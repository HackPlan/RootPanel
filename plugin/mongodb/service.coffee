jade = require 'jade'
path = require 'path'
async = require 'async'

config = require '../../config'

mAccount = require '../../core/model/account'

module.exports =
  enable: (account, callback) ->
    callback()

  delete: (account, callback) ->
    callback()

  widget: (account, callback) ->
    admin = app.db.admin()
    admin.authenticate config.mongodb.user, config.mongodb.password, ->
      admin.listDatabases (err, result) ->
        dbs = _.filter result.databases, (i) ->
          return i.name.slice(0, account.username.length + 1) == "#{account.username}_"

        jade.renderFile path.join(__dirname, 'view/widget.jade'),
          account: account
          dbs: dbs
        , (err, html) ->
          callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
