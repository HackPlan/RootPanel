{utils, config, models, mabolo} = app
{ObjectID} = mabolo

Notification = mabolo.model 'Notification',
  target:
    required: true
    type: Object

  type:
    required: true
    type: String
    enum: []

  created_at:
    type: Date
    default: -> new Date()

  read_at:
    type: Date

  title:
    required: true
    type: String

  body:
    required: true
    type: String

  body_html:
    required: true
    type: String

  options:
    type: Object

Notification::isGroupNotice = ->
  return @target instanceof ObjectID

Notification::sendMail = ->
  sendMail = (to, subject, html) ->
    Q.Promise (resolve, reject) ->
      app.mailer.sendMail
        from: config.email.from
        replyTo: config.email.reply_to
        to: to
        subject: subject
        html: html
      , (err, result) ->
        if err
          reject err
        else
          resolve result

  @populate().then =>
    if @isGroupNotice()
      Account.findByGroup(@target).then (accounts) =>
        Q.all accounts.map (account) =>
          sendMail account.email, @title, @body_html

    else
      Account.findById(@target).then (account) =>
        sendMail account.email, @title, @body_html

Notification::populate = ->
  @provider = rp.extends.notification.byName @type
  @provider.populateNotification @
