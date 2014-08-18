jade = require 'jade'
path = require 'path'
mysql = require 'mysql'
async = require 'async'

config = require '../../config'
plugin = require '../../core/plugin'

mAccount = require '../../core/model/account'

connection = mysql.createConnection config.plugins.mysql.connection
connection.connect()

module.exports =
  enable: (account, callback) ->
    connection.query "CREATE USER '#{account.username}'@'localhost' IDENTIFIED BY '#{mAccount.randomSalt()}';", (err, rows) ->
      throw err if err

      connection.query "GRANT ALL PRIVILEGES ON  `#{account.username}\\_%%` . * TO  '#{account.username}'@'localhost';", (err, rows) ->
        throw err if err
        callback()

  delete: (account, callback) ->
    connection.query "DROP USER '#{account.username}'@'localhost';", (err, rows) ->
      throw err if err

      connection.query "SHOW DATABASES LIKE '#{account.username}_%';", (err, rows) ->
        throw err if err

        databases_to_delete = _.filter _.pluck(rows, "Database (#{account.username}_%)"), (item) ->
          if item[..account.username.length] == "#{account.username}_"
            return true
          else
            return false

        async.each databases_to_delete, (name, callback) ->
          connection.query "DROP DATABASE `#{name}`;", (err, rows) ->
            throw err if err
            callback()
        , ->
          callback()

  widget: (account, callback) ->
    connection.query "SELECT `table_schema` 'name', sum(`data_length` + `index_length`) / 1024 / 1024 'size', sum(`data_free`) / 1024 / 1024 'free' FROM `information_schema`.`TABLES` WHERE `TABLE_SCHEMA` LIKE '#{account.username}_%' GROUP BY table_schema;", (err, rows) ->
      jade.renderFile path.join(__dirname, 'view/widget.jade'),
        dbs: rows
      , (err, html) ->
        callback html

  storage: (account, callback) ->
    connection.query "SELECT `table_schema` 'name', sum(`data_length` + `index_length`) / 1024 / 1024 'size', sum(`data_free`) / 1024 / 1024 'free' FROM `information_schema`.`TABLES` WHERE `TABLE_SCHEMA` LIKE '#{account.username}_%' GROUP BY table_schema;", (err, rows) ->
      callback null, _.reduce rows, (memo, db) ->
        return memo + db.size
      , 0
