express = require 'express'
mysql = require 'mysql'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

exports.use (req, res, next) ->
  mAccount.authenticate req.token, (account) ->
    unless account
      return res.json 400, error: 'auth_failed'

    unless 'mysql' in account.attribute.service
      return res.json 400, error: 'not_in_service'

    req.account = account
    next()

exports.post '/update_passwd/', (req, res) ->
  unless req.body.passwd or not /^[A-Za-z0-9\-_]+$/.test req.body.passwd
    return res.json 400, error: 'invalid_passwd'

  connection = mysql.createConnection config.plugins.mysql.connection
  connection.connect()

  connection.query "SET PASSWORD FOR '#{req.account.username}'@'localhost' = PASSWORD('#{req.body.passwd}');", (err, rows, fields) ->
    throw err if err
    connection.end()
    res.json {}
