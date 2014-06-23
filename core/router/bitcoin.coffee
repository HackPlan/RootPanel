config = require '../../config'
plugin = require '../plugin'
bitcoin = require '../bitcoin'
{getParam} = require './middleware'

module.exports = exports = express.Router()

exports.get '/blockchain_callback', (req, res) ->
  bitcoin.doCallback req.body, (result) ->
    res.send result
