child_process = require 'child_process'

service = require './service'
{assertInService} = require '../../core/router/middleware'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

exports.use assertInService 'redis'

exports.post '/switch', (req, res) ->
  unless req.body.enable in [true, false]
    return res.error 'invalid_enable'

  service.switch req.account, req.body.enable, ->
    res.json {}
