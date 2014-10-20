{pluggable} = app
{selectModelEnum} = pluggable
{_, ObjectId, mongoose} = app.libs

SecurityLog = mongoose.Schema
  account_id:
    required: true
    type: ObjectId
    ref: 'Account'

  type:
    required: true
    type: String
    enum: ['update_password', 'update_setting', 'update_email'].concat selectModelEnum 'SecurityLog', 'type'

  created_at:
    type: Date
    default: Date.now

  payload:
    type: Object
    default: {}

  token:
    required: true
    type: ObjectId
    ref: 'Token'

_.extend app.schemas,
  SecurityLog: SecurityLog

exports.create = (account, type, token, payload, callback) ->
  matched_token = _.findWhere account.tokens,
    token: token

  exports.insert
    account_id: account._id
    type: type
    token: matched_token
    payload: payload
    created_at: new Date()
  , (err, result) ->
    callback _.first result
