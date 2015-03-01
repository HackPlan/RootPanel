{models, logger, mabolo} = app
{_} = app.libs
{ObjectID} = mabolo

SecurityLog = mabolo.model 'SecurityLog',
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  type:
    required: true
    type: String
    enum: ['revoke_token', 'update_password', 'update_email', 'update_preferences']

  created_at:
    type: Date
    default: -> new Date()

  payload:
    type: Object

  token:
    type: Object
