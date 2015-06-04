Mabolo = require 'mabolo'
_ = require 'lodash'
Q = require 'q'

{ObjectID} = Mabolo

###
  Model: Notification.
###
module.exports = Notification = Mabolo.model 'Notification',
  # Public: Plugin that created this notification
  source:
    required: true
    type: String

  # Public: Account or group that noticed
  target:
    required: true
    type: Object

  # Public: Type of notification
  type:
    type: String

  # Public: Date that this notification has been read
  read_at:
    type: Date

  # Public: Title of this notification
  title:
    required: true
    type: String

  # Public: Markdown content of notification
  body:
    required: true
    type: String

  # Public: HTML content of notification
  body_html:
    required: true
    type: String

  # Custom options of notification
  options:
    type: Object

  created_at:
    type: Date
    default: -> new Date()

###
  Public: Check that target is a group.

  Return {Boolean}.
###
Notification::isGroupNotice = ->
  return @target not instanceof ObjectID

###
  Public: Send a email about this notification.

  Return {Promise}.
###
Notification::sendMail = ->
  sendMail = (to, subject, html) ->
    Q.Promise (resolve, reject) ->
      root.mailer.sendMail
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
      sendMail @account.email, @title, @body_html

###
  Public: Populate.

  This function will populate following fields:

  * `account`: {Account} if `target` is account.

  return {Promise}
###
Notification::populate = ->
  if _.isString(@target) or @account
    return Q @

  Account.findById(@target).then (account) =>
    return _.extend @,
      account: account
