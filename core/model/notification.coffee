module.exports = exports = app.db.collection 'notifications'

sample =
  account_id: ObjectID()
  created_at: Date()
  level: 'notice/event/log'
  type: 'payment_success'
  meta:
    amount: 10

