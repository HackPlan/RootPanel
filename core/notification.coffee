async = require 'async'

mAccount = require './model/account'
mNotification = require './model/notification'

i18n = require './i18n'
config = require '../config'

{NOTICE, EVENT, LOG} = module.exports = exports =
  NOTICE: 'notice'
  EVENT: 'event'
  LOG: 'log'

exports.notice_level =
  ticket_create: NOTICE
  ticket_reply: NOTICE
  ticket_update: EVENT

exports.createNotice = (account, type, notice, callback) ->
  level = exports.notice_level[type]

  mNotification.createNotice account, null, type, level, notice, (notification) ->
    app.mailer.sendMail
      from: config.email.send_from
      to: account.email
      subject: notice.title
      html: notice.body
    , ->
      callback notification

exports.createGroupNotice = (group, type, notice, callback) ->
  level = exports.notice_level[type]

  mNotification.createNotice null, group, type, level, notice, (notification) ->
    unless level == NOTICE
      callback notification

    mAccount.find
      groups: 'root'
    .toArray (err, accounts) ->
      async.each accounts, (account, callback) ->
        app.mailer.sendMail
          from: config.email.send_from
          to: account.email
          subject: notice.title
          html: notice.body
        , callback
      , (err) ->
        throw err if err
        callback notification
