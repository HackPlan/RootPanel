{_, ObjectId, mongoose} = app.libs

SecurityLog = mongoose.Schema
  account_id:
    required: true
    type: ObjectId
    ref: 'Account'

  type:
    required: true
    type: String
    enum: ['revoke_token', 'update_password', 'update_email', 'update_preferences']

  created_at:
    type: Date
    default: Date.now

  payload:
    type: Object

  token:
    type: Object

_.extend app.models,
  SecurityLog: mongoose.model 'SecurityLog', SecurityLog
