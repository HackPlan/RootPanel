{utils, config} = app
{markdown, fs, path, express} = app.libs
{requireInService} = app.middleware

shadowsocks = require './shadowsocks'

module.exports = exports = express.Router()

exports.use requireInService 'shadowsocks'

exports.post '/reset_password', (req, res) ->
  password = utils.randomString 10

  req.account.update
    $set:
      'pluggable.shadowsocks.password': password
  , ->
    shadowsocks.updateConfigure ->
      res.json {}

exports.post '/switch_method', (req, res) ->
  unless req.body.method in config.plugins.shadowsocks.available_ciphers
    return res.error 'invalid_method'

  if req.body.method == req.account.pluggable.shadowsocks.method
    return res.error 'already_in_method'

  req.account.update
    $set:
      'pluggable.shadowsocks.method': req.body.method
  , ->
    shadowsocks.updateConfigure ->
      res.json {}
