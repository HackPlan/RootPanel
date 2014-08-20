{renderAccount} = require '../../core/router/middleware'

module.exports = exports = express.Router()

if config.plugins.rpvhost.index_page
  app.get '/', renderAccount, (req, res) ->
    res.render path.join(__dirname, './view/index')
