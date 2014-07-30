child_process = require 'child_process'
jade = require 'jade'
path = require 'path'
fs = require 'fs'

plugin = require '../../core/plugin'

mAccount = require '../../core/model/account'

template =
  site_configure: fs.readFileSync("#{__dirname}/template/site_configure.conf").toString()
  user_configure: fs.readFileSync("#{__dirname}/template/user_configure.conf").toString()

siteSummary = (site) ->
  type = do ->
    unless site['location']['/']
      return 'static'

    if site['location']['/']['proxy_pass']
      return 'proxy'

    if site['location']['/']['uwsgi_pass']
      return 'uwsgi'

    if site['location']['/']?['try_files']
      for item in site['location']['/']['try_files']
        if item.match(/\.php/)
          return 'factcgi'

    return 'static'

  switch type
    when 'static', 'factcgi'
      return "#{type}; root: #{site['root']}"
    when 'proxy'
      return "#{type}; url: #{site['location']['/']['proxy_pass']}"
    when 'uwsgi'
      return "#{type}; socket: #{site['location']['/']['uwsgi_pass']}"

module.exports =
  enable: (account, callback) ->
    mAccount.update _id: account._id,
      $set:
        'attribute.plugin.nginx.sites': []
    , ->
      callback()

  delete: (account, callback) ->
    child_process.exec "sudo rm /etc/nginx/sites-enabled/#{account.username}.conf", ->
      callback()

  writeConfig: (account, callback) ->
    mAccount.findId account._id, (err, account) ->
      unless account.attribute.plugin.nginx.sites
        return callback()

      sites_configure = []

      for site in account.attribute.plugin.nginx.sites
        if site.is_enable
          sites_configure.push _.template template.site_configure,
            site: site

      user_configure = _.template template.user_configure,
        sites: sites_configure

      plugin.writeConfig "/etc/nginx/sites-enabled/#{account.username}.conf", user_configure, ->
        child_process.exec 'sudo service nginx reload', (err) ->
          throw err if err
          callback()

  siteSummary: siteSummary

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'),
      account: account
      siteSummary: siteSummary
    , (err, html) ->
      throw err if err
      callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
