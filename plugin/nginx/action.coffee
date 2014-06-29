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

assertJsonConfig = (config) ->


exports.use (req, res, next) ->
  req.inject [requestAuthenticate], ->
    unless 'nginx' in req.account.attribute.services
      return res.error 'not_in_service'

    next()

exports.post '/update_site/', (req, res) ->
  unless req.body.action in ['create', 'update', 'delete']
    return res.error 'invalid_action'

  checkSite = (callback) ->
    if req.body.action == 'create'
      callback null
    else
      mAccount.findOne
        'attribute.plugin.nginx.sites._id': new ObjectID req.body.id
      , (err, account) ->
        if account?._id.toString() == req.account._id.toString()
          callback null
        else
          callback true

  checkSiteConfig = (callback) ->
    unless req.body.action == 'delete'
      if req.body.type == 'json'
        err = assertJsonConfig req.body.config

        if err
          callback err
        else
          callback null
      else
        callback 'invalid_type'
    else
      callback null

  checkSite (err) ->
    if err
      return res.error 'forbidden'

    checkSiteConfig (err) ->
      if err
        return res.json err

      removeSite = (callback) ->
        mAccount.update _id: account._id,
          $pull:
            'attribute.plugin.nginx.sites': new ObjectID req.body.id
        , callback

      addSite = (callback) ->
        mAccount.update _id: req.account._id,
          $push:
            'attribute.plugin.nginx.sites': req.body.config
        , callback

      execModification = (callback) ->
        if req.body.action = 'create'
          addSite callback
        else if req.body.action = 'update'
          removeSite ->
            addSite callback
        else if req.body.action = 'delete'
          removeSite callback

      execModification ->
        res.json {}
