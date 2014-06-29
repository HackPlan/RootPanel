child_process = require 'child_process'

utils = require '../../core/router/utils'
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
  # default {}
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

  assertJsonConfig = (config) ->
    checkHomeFile = (file) ->

    unless config.listen in [80]
      return 'invalid_listen'

    for domain in config.server_name
      unless utils.rx.test domain
        return 'invalid_server_name'

    if config.auto_index
      config.auto_index = if config.auto_index then true else false

    config.index ?= ['index']

    for file in config.index
      unless utils.rx.test file
        return 'invalid_index'

    unless checkHomeFile config.root
      return 'invalid_root'

    config.location ?= {}

    for path, rules of config.location
      unless path in ['/']
        return 'invalid_location'

      for name, value of rules
        if name == 'fastcgi_pass'
          # TODO: check unix socket path

        if name == 'fastcgi_index'
          for file in value
            unless utils.rx.test file
              return 'fastcgi_index'

    return null

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
