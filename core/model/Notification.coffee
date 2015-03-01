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
