{markdown} = require 'markdown'

###
  Manager: Notification manager,
  You can access a global instance via `root.notifications`.
###
module.exports = class NotificationManager
  default_options:
    email: false

  ###
    Public: Notify to account.

    * `account` {Account}
    * Other options same as {NotificationManager::notify}.

    Return {Promise}.
  ###
  notifyAccount: (account, options...) ->
    @notify account._id, options...

  ###
    Public: Notify to group.

    * `group` {String}
    * Other options same as {NotificationManager::notify}.

    Return {Promise}.
  ###
  notifyGroup: (group, options...) ->
    @notify group, options...

  ###
    Public: Create a notification.

    * `target` {ObjectID} of {Account} or {String} of group name.
    * `notification` {Object}

      * `type` {String}
      * `title` {String}
      * `body` {String}
      * `source` {String}
      * `options` (optional) {Object}
      * `email` (optional) {Boolean} Default to false.

    Return {Promise}.
  ###
  notify: (target, {type, title, body, options, source, email}) ->
    if email == undefined
      {email} = @default_options

    Notification.create
      source: source
      target: target
      title: title
      body: body
      options: options
      body_html: markdown.toHTML body
    .then (notification) ->
      if email
        notification.sendMail()
