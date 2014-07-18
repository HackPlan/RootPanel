child_process = require 'child_process'

service = require './service'
configure = require './configure'

{requestAuthenticate, getParam} = require '../../core/router/middleware'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

sample =
  _id: '53c96734c2dad7d6208a0fbe'
  listen: 80
  server_name: ['domain1', 'domain2']
  auto_index: false
  index: ['index.html']
  root: '/home/user/web'
  location:
    '/':
      fastcgi_pass: 'unix:///home/user/phpfpm.sock'
      fastcgi_index: ['index.php']

exports.use (req, res, next) ->
  req.inject [requestAuthenticate], ->
    unless 'nginx' in req.account.attribute.services
      return res.error 'not_in_service'

    next()

exports.all '/site_config', getParam, (req, res) ->
  site = _.find req.account.attribute.plugin.nginx.sites, (i) ->
    return i._id.toString() == req.body.id

  site.id = site._id
  delete site._id

  res.json site

exports.post '/update_site', (req, res) ->
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
        configure.assert req.account, req.body.config, req.body.id, (err) ->
          callback err
      else
        callback 'invalid_type'
    else
      callback null

  checkSite (err) ->
    if err
      return res.error 'forbidden'

    checkSiteConfig (err) ->
      if err
        return res.error err

      removeSite = (callback) ->
        mAccount.update _id: req.account._id,
          $pull:
            'attribute.plugin.nginx.sites':
              '_id': new ObjectID req.body.id
        , callback

      addSite = (callback) ->
        req.body.config._id = new ObjectID()
        req.body.config = _.pick req.body.config, _.keys(sample)
        mAccount.update _id: req.account._id,
          $push:
            'attribute.plugin.nginx.sites': req.body.config
        , callback

      execModification = (callback) ->
        if req.body.action == 'create'
          addSite callback
        else if req.body.action == 'update'
          removeSite ->
            addSite callback
        else if req.body.action == 'delete'
          removeSite callback

      execModification ->
        service.writeConfig req.account, ->
          res.json {}
