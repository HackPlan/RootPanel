child_process = require 'child_process'
jade = require 'jade'
path = require 'path'
async = require 'async'

mAccount = require '../../core/model/account'

module.exports =
  enable: (account, callback) ->
    callback()

  delete: (account, callback) ->
    callback()

  writeConfig: (account, callback) ->
    mAccount.findId account._id, (err, account) ->
      unless account.attribute.plugin.nginx.sites
        return callback()

      for site in account.attribute.plugin.nginx.sites
        
      callback()

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'), {}, (err, html) ->
      callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
