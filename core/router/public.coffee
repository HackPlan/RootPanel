plugin = require '../plugin'
{renderAccount} = require './middleware'

module.exports = exports = express.Router()

exports.get '/services', renderAccount, (req, res) ->
  async.map config.plugin.availablePlugin, (item, callback) ->
    p = plugin.get item
    p.service.preview (html) ->
      callback null, html

  , (err, result) ->
    res.render 'public/services',
      plans: _.values(config.plans)
      services: result
