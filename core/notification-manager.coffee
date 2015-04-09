{markdown} = require 'markdown'

module.exports = class NotificationManager
  default_options:
    source: null
    level: 'event'
    email: false

  notifyAccount: (account, options) ->
    @notify account._id, options

  notifyGroup: (group, options) ->
    @notify group, options

  notify: (target, options) ->
    {level, email, source} = _.defaults options, @default_options

    Notification.create
      source: source
      target: target
      title: title
      body: body
      body_html: markdown.toHTML body
    .then (notification) ->
      if email
        notification.sendMail()
