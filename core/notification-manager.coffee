{markdown} = require 'markdown'

module.exports = class NotificationManager
  default_options:
    email: false

  notifyAccount: (account, options...) ->
    @notify account._id, options...

  notifyGroup: (group, options...) ->
    @notify group, options...

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
