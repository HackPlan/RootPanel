child_process = require 'child_process'
jade = require 'jade'
path = require 'path'
tmp = require 'tmp'
fs = require 'fs'

plugin = require '../../core/plugin'

mAccount = require '../../core/model/account'

module.exports =
  enable: (account, callback) ->
    mAccount.update _id: account._id,
      $set:
        'attribute.plugin.memcached.is_enable': false
    , ->
      callback()

  delete: (account, callback) ->
    if account.attribute.plugin.memcached.is_enable
      this.switch account, false, callback
    else
      callback()

  switch: (account, is_enable, callback) ->
    callback()

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
