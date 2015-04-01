{markdown} = require 'markdown'

class NotificationType
  defaults:
    name: null
    level: 'event'
    email: false
    populateNotification: (notification) -> notification

  constructor: (options) ->
    _.extend @, @defaults, options

  notifyAccount: (account, title, body) ->
    Notification.create(
      type: @name
      target: account._id
      title: title
      body: body
      body_html: markdown.toHTML body
    ).then (notification) =>
      if @email
        

  notifyGroup: (group, title, body) ->
    Notification.create
      type: @name
      target: group
      title: title
      body: body
      body_html: markdown.toHTML body

module.exports = class NotificationManager
  constructor: ->
    @types = {}

  register: (options) ->
    {name} = options

    unless name
      throw new Error 'notification type should have a name'

    if @types[name]
      throw new Error "notification type `#{name}` already exists"

    @types[name] = new NotificationType options

  all: ->
    return _.values @types

  byName: (name) ->
    return @types[name]
