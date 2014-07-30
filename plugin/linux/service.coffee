jade = require 'jade'
path = require 'path'
monitor = require './monitor'

module.exports =
  enable: (account, callback) ->
    callback()

  delete: (account, callback) ->
    callback()

  widget: (account, callback) ->
    monitor.monitoringStorage ->
      jade.renderFile path.join(__dirname, 'view/widget.jade'),
        account: account
        resources_usage: do ->
          usage = monitor.resources_usage[account.username] ? {cpu: 0, memory: 0}
          return {
            cpu:
              now_per: (usage.cpu / account.attribute.resources_limit.cpu * 100).toFixed()
              now: usage.cpu.toFixed(1)
              limit: account.attribute.resources_limit.cpu
            memory:
              now_per: (usage.memory / account.attribute.resources_limit.memory * 100).toFixed()
              now: usage.memory.toFixed(1)
              limit: account.attribute.resources_limit.memory
          }

        storage_usage: do ->
          usage = monitor.storage_usage[account.username]
          now_per = (usage.size_used / 1000 / account.attribute.resources_limit.storage * 100).toFixed()
          return {
            now_per: now_per
            now: (usage.size_used / 1000).toFixed(1)
            limit: account.attribute.resources_limit.storage
            color: if now_per < 90 then 'success' else 'danger'
          }

      , (err, html) ->
        throw err if err
        callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
