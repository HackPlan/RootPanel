child_process = require 'child_process'
jade = require 'jade'
path = require 'path'
tmp = require 'tmp'
fs = require 'fs'

mAccount = require '../../core/model/account'

template =
  site_configure: fs.readFileSync './template/site_configure'
  user_configure: fs.readFileSync './template/user_configure'

module.exports =
  enable: (account, callback) ->
    callback()

  delete: (account, callback) ->
    child_process.exec "sudo rm /etc/nginx/sites-enabled/#{account.username}.conf", ->
      callback()

  writeConfig: (account, callback) ->
    mAccount.findId account._id, (err, account) ->
      unless account.attribute.plugin.nginx.sites
        return callback()

      sites_configure = {}

      for site in account.attribute.plugin.nginx.sites
        sites_configure.push _.template template.site_configure,
          site: site

      configure = _.template template.user_configure,
        sites: sites_configure

      tmp.file
        mode: 0o750
      , (err, filepath, fd) ->
        fs.writeSync fd, configure, 0, 'utf8'
        fs.closeSync fd

        child_process.exec "sudo cp #{filepath} /etc/nginx/sites-enabled/#{account.username}.conf", (err) ->
          throw err if err

          child_process.exec 'sudo service nginx restart', (err) ->
            throw err if err
            callback()

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'), {}, (err, html) ->
      callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
