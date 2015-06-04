describe 'model.notification', ->
  Notification = require '../../model/notification'

  describe '::isGroupNotice', ->
    it 'return true', ->
      createNotification(target: 'root').then (notification) ->
        notification.isGroupNotice().should.be.true

    it 'return false', ->
      createAccount().then (account) ->
        createNotification(target: account._id).then (notification) ->
          notification.isGroupNotice().should.be.false

createNotification = (options) ->
  return root.Notification.create _.defaults options,
    source: 'billing'
    title: 'Title'
    body: 'Body'
    body_html: 'Body'
