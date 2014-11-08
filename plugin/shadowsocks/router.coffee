{markdown, fs, path, express} = app.libs
{renderAccount, requireInService, requireAuthenticate} = require '../../core/middleware'

module.exports = exports = express.Router()

exports.use requireInService 'shadowsocks'

exports.post '/reset_password', (req, res) ->
  password = mAccount.randomString 10

  mAccount.update _id: req.account._id,
    $set:
      'attribute.plugin.shadowsocks.password': password
  , ->
    req.account.attribute.plugin.shadowsocks.password = password

    service.restart req.account, ->
      service.restartAccount req.account, ->
        res.json {}
