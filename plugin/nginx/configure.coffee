mAccount = require '../../core/model/account'

exports.assert = (account, config, site_id, callback) ->
  config.index ?= ['index']
  config.location ?= {}

  if config.is_enable == undefined
    config.is_enable = true

  unless config.listen in [80]
    return callback 'invalid_listen'

  async.each config.server_name, (domain, callback) ->
    unless utils.rx.domain.test domain
      return callback 'invalid_server_name'

    mAccount.findOne
      'attribute.plugin.nginx.sites.server_name': domain
    , (err, result) ->
      unless result
        return callback null

      site = _.find result.attribute.plugin.nginx.sites, (i) ->
        return domain in i.server_name

      if site._id.toString() == site_id?.toString()
        callback null
      else
        callback 'unavailable_server_name'

  , (err) ->
    if err
      return callback err

    if config.auto_index
      config.auto_index = if config.auto_index then true else false

    for file in config.index
      unless utils.rx.filename.test file
        return callback 'invalid_index'

    unless utils.checkHomeFilePath account, config.root
      return callback 'invalid_root'

    for path, rules of config.location
      unless path in ['/', '~ \\.php$']
        return callback 'invalid_location'

      for name, value of rules
        if name == 'fastcgi_pass'
          fastcgi_prefix = 'unix://'

          unless value.slice(0, fastcgi_prefix.length) == fastcgi_prefix
            return callback 'invalid_fastcgi_pass'

          unless utils.checkHomeFilePath account, value.slice fastcgi_prefix.length
            return callback 'invalid_fastcgi_pass'
        else if name == 'fastcgi_index'
          for file in value
            unless utils.rx.filename.test file
              return callback 'invalid_fastcgi_index'
        else if name == 'include'
          unless value == 'fastcgi_params'
            return callback 'invalid_include'
        else if name == 'try_files'
          for item in value
            unless item in ['$uri', '$uri/', '/index.php?$args']
              return callback 'invalid_try_files'
        else
          return callback 'unknown_command'

    callback null