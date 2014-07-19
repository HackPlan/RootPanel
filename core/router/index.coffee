{renderAccount} = require './middleware'

module.exports = exports = express.Router()

exports.get '/', renderAccount, (req, res) ->
  res.render 'index'
