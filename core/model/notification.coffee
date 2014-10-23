{pluggable} = app
{selectModelEnum} = pluggable
{_, ObjectId, mongoose} = app.libs

Notification = mongoose.Schema
  account_id:
    type: ObjectId
    ref: 'Account'
    default: null

  group_name:
    type: String
    default: null

  type:
    required: true
    type: String
    enum: ['payment_success']

  level:
    required: true
    type: String
    enum: ['notice', 'event', 'log']

  created_at:
    type: Date
    default: Date.now

  payload:
    type: Object
    default: {}

_.extend app.models,
  Notification: mongoose.model 'Notification', Notification

exports.createNotice = (account, group_name, type, level, meta, callback) ->
  exports.insert
    account_id: account?._id ? null
    group_name: group_name ? null
    level: level
    type: type
    meta: meta
  , (err, result) ->
    callback _.first result
