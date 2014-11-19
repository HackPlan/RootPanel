{async, _} = app.libs
{i18n, config, logger, mailer} = app
{Account, Notification} = app.models

{NOTICE, EVENT, LOG} = _.extend exports,
  NOTICE: 'notice'
  EVENT: 'event'
  LOG: 'log'

exports.notices_level = notices_level =
  ticket_create: NOTICE
  ticket_reply: NOTICE
  ticket_update: EVENT

exports.createNotice = (account, type, notice, callback) ->
  level = exports.notices_level[type]

  notification = new Notification
    account_id: account._id
    type: type
    level: level
    payload: notice

  notification.save ->
    app.mailer.sendMail
      from: config.email.send_from
      to: account.email
      subject: notice.title
      html: notice.body
    , ->
      callback notification

exports.createGroupNotice = (group, type, notice, callback) ->
  level = exports.notices_level[type]

  notification = new Notification
    group_name: group
    type: type
    level: level
    payload: notice

  notification.save ->
    unless level == NOTICE
      callback notification

    Account.find
      groups: 'root'
    , (err, accounts) ->
      async.each accounts, (account, callback) ->
        app.mailer.sendMail
          from: config.email.send_from
          to: account.email
          subject: notice.title
          html: notice.body
        , callback
      , (err) ->
        logger.error err if err
        callback notification
