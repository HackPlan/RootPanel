child_process = require 'child_process'

plugin = require '../../core/plugin'

{requestAuthenticate} = require '../../core/router/middleware'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

sample =
  # required
  listen: 80
  # required
  server_name: ['domain1', 'domain2']
  # default false
  auto_index: false
  # default ['index.html']
  index: ['index.html']
  # required
  root: '/home/user/web'
  # default []
  location:
    '/':
      fastcgi_pass: 'unix:///home/user/phpfpm.sock'
      fastcgi_index: ['index.php']

exports.use (req, res, next) ->
  req.inject [requestAuthenticate], ->
    unless 'nginx' in req.account.attribute.services
      return res.error 'not_in_service'

    next()

exports.post '/update_site/', (req, res) ->
  unless req.body.action in ['create', 'update', 'delete']
    return res.error 'invalid_action'

  if req.body.type == 'json'

  else
    return res.json 'invalid_type'
