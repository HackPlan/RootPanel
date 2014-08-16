service = require './service'
{requireInService} = require '../../core/router/middleware'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

exports.use requireInService 'shadowsocks'

exports.post '/reset_password', (req, res) ->
  mAccount.update _id: req.account._id,
    $set:
      'attribute.plugin.shadowsocks.password': mAccount.randomSalt()
  , ->
    service.restart req.account, ->
      res.json {}
