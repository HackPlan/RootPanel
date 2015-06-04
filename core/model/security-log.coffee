Mabolo = require 'mabolo'
_ = require 'lodash'

{ObjectID} = Mabolo

###
  Model: Security log
###
module.exports = SecurityLog = Mabolo.model 'SecurityLog',
  # Public: Related account
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  # Public: Type of log
  type:
    required: true
    type: String
    enum: [
      'login', 'revoke_token'
      'update_password', 'update_email', 'update_preferences'
    ]

  # Public: Custom options of log
  options:
    type: Object
    default: -> {}

  # Public: {Token} that created this log
  token:
    type: Object

  created_at:
    type: Date
    default: -> new Date()

###
  Public: Create log.

  * `account` {Account}
  * `log` {Object}

    * `token` {Token}
    * `type` {String}
    * `options` (optional) {Object}

  Return {Promise} resolve with created log.
###
SecurityLog.createLog = (account, {token, type, options}) ->
  @create
    account_id: account._id
    options: options
    token: _.pick token, 'type', 'code', 'created_at', 'options'
    type: type
