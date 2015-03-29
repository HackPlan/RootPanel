{utils, config, models, mabolo} = app
{_, async} = app.libs
{ObjectID} = mabolo

Notification = mabolo.model 'Notification',
  account_id:
    type: ObjectID
    ref: 'Account'

  group_name:
    type: String

  type:
    required: true
    type: String
    enum: ['payment_success', 'ticket_create', 'ticket_reply']

  level:
    required: true
    type: String
    enum: ['notice', 'event', 'log']

  created_at:
    type: Date
    default: -> new Date()

  payload:
    type: Object

notices_level =
  ticket_create: 'notice'
  ticket_reply: 'notice'
  ticket_update: 'event'

Notification.createNotice = (account, type, notice) ->
  level = notices_level[type]

  Notification.create
    account_id: account._id
    type: type
    level: level
    payload: notice
  .then ->
    app.mailer.sendMail
      from: config.email.send_from
      to: account.email
      subject: notice.title
      html: notice.body
    , ->
      callback notification

Notification.createGroupNotice = (group, type, notice) ->
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
