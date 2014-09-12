mAccount = require '../../core/model/account'

exports.checkHomeFilePath = (account, path) ->
  home_dir = "/home/#{account.username}/"

  unless /^[/A-Za-z0-9_\-\.]+\/?$/.test path
    return false

  unless path.slice(0, home_dir.length) == home_dir
    return false

  unless path.length < 512
    return false

  unless path.slice(-3) != '/..'
    return false

  unless path.indexOf('/../') == -1
    return false

  return true

exports.checkHomeUnixSocket = (account, path) ->
  fastcgi_prefix = 'unix://'

  unless path.slice(0, fastcgi_prefix.length) == fastcgi_prefix
    return false

  unless exports.checkHomeFilePath account, path.slice fastcgi_prefix.length
    return false

  return true

exports.assert = (account, config, site_id, callback) ->
  config.index ?= ['index.html']
  config.location ?= {}

  unless config.is_enable == false
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

    unless _.isArray config.index
      return callback 'invalid_index'

    for file in config.index
      unless utils.rx.filename.test file
        return callback 'invalid_index'

    if config.root
      unless utils.checkHomeFilePath account, config.root
        return callback 'invalid_root'

    for path, rules of config.location
      unless path in ['/', '~ \\.php$']
        return callback 'invalid_location'

      for name, value of rules
        switch name
          when 'fastcgi_pass'
            rules['fastcgi_index'] ?= ['index.php']
            unless utils.checkHomeUnixSocket account, value
              return callback 'invalid_fastcgi_pass'

          when 'uwsgi_pass'
            unless utils.checkHomeUnixSocket account, value
              return callback 'invalid_fastcgi_pass'

          when 'proxy_pass'
            rules['proxy_redirect'] ?= false
            unless utils.checkHomeUnixSocket(account, value) or utils.rx.url.test value
              return callback 'invalid_proxy_pass'

          when 'proxy_set_header'
            for header_name, header_value of value
              switch header_name
                when 'Host'
                  unless header_value == '$host' or utils.rx.domain.test header_value
                    return callback 'invalid_proxy_set_header'
                else
                  return callback 'invalid_proxy_set_header'

          when 'proxy_redirect'
            rules['proxy_redirect'] = if value then true else false

          when 'fastcgi_index'
            for file in value
              unless utils.rx.filename.test file
                return callback 'invalid_fastcgi_index'

          when 'include'
            unless value in ['fastcgi_params', 'uwsgi_params']
              return callback 'invalid_include'

          when 'try_files'
            for item in value
              unless item in ['$uri', '$uri/', '/index.php?$args']
                return callback 'invalid_try_files'

          else
            return callback 'unknown_command'

    callback null