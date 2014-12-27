{pluggable, utils, config, models} = app
{_, async, mongoose, mongooseUniqueValidator} = app.libs
{Financial, SecurityLog, Component} = app.models

Plan = require '../interface/Plan'
billing = require '../billing'

process.nextTick ->
  {Financial, SecurityLog, Component} = app.models

Token = mongoose.Schema
  type:
    required: true
    type: String
    enum: ['full_access']

  token:
    required: true
    sparse: true
    unique: true
    type: String

  created_at:
    type: Date
    default: Date.now

  update_at:
    type: Date
    default: Date.now

  payload:
    type: Object

Token.methods.revoke = (callback) ->
  @ownerDocument().update
    $pull:
      tokens:
        token: @token
  , callback

_.extend app.models,
  Token: mongoose.model 'Token', Token

Account = mongoose.Schema
  username:
    required: true
    unique: true
    type: String

  email:
    lowercase: true
    required: true
    unique: true
    type: String

  password:
    type: String

  password_salt:
    type: String

  created_at:
    type: Date
    default: Date.now

  groups:
    type: Array

  tokens: [
    mongoose.modelSchemas.Token
  ]

  preferences:
    type: Object

  plans:
    type: Object
    default: {}

  balance:
    type: Number
    default: 0

  arrears_at:
    type: Date

  pluggable:
    type: Object
    default: {}

  resources_limit:
    type: Object

Account.plugin mongooseUniqueValidator,
  message: 'unique_validation_error'

Account.path('email').validate (email) ->
  return utils.rx.email.test email
, 'invalid_email'

Account.path('username').validate (username) ->
  return utils.rx.username.test username
, 'invalid_username'

Account.path('username').validate (username, callback) ->
  async.each pluggable.selectHook('account.username_filter'), (hook, callback) ->
    hook.filter username, (is_allow) ->
      if is_allow
        callback()
      else
        callback true

  , (not_allow) ->
    if not_allow
      callback()
    else
      callback true
, 'username_exist'

# @param account: username, email, password
# @param callback(err, account)
Account.statics.register = (account, callback) ->
  password_salt = utils.randomSalt()

  {username, email, password} = account

  account = new @
    username: username
    email: email
    password: utils.hashPassword(password, password_salt)
    password_salt: password_salt

    preferences:
      avatar_url: "//cdn.v2ex.com/gravatar/#{utils.md5(email)}"
      language: 'auto'
      timezone: config.i18n.default_timezone

    pluggable: {}

  async.each pluggable.selectHook('account.before_register'), (hook, callback) ->
    hook.filter account, callback
  , ->
    account.save (err) ->
      callback err, account

# @param callback(account)
Account.statics.search = (stuff, callback) ->
  @findOne {username: stuff}, (err, account) =>
    if account
      return callback account

    @findOne {email: stuff}, (err, account) =>
      if account
        return callback account

      @findById stuff, (err, account) ->
        callback account

# @param callback(token)
Account.statics.generateToken = (callback) ->
  token = utils.randomSalt()

  @findOne
    'tokens.token': token
  , (err, result) ->
    if result
      @generateToken callback
    else
      callback token

# @param callback(Token, Account)
Account.statics.authenticate = (token, callback) ->
  unless token
    return callback()

  @findOneAndUpdate
    'tokens.token': token
  ,
    $set:
      'tokens.$.updated_at': new Date()
  , (err, account) ->
    matched_token = _.findWhere account?.tokens,
      token: token

    callback matched_token, account

# @param callback(err, Token)
Account.methods.createToken = (type, payload, callback) ->
  models.Account.generateToken (token) =>
    token = new models.Token
      type: type
      token: token
      payload: payload

    token.validate (err) =>
      return callback err if err

      @tokens.push token

      @save (err) ->
        return callback err if err

        callback null, token

Account.methods.matchPassword = (password) ->
  return @password == utils.hashPassword(password, @password_salt)

Account.methods.updatePassword = (password, callback) ->
  @password_salt = utils.randomSalt()
  @password = utils.hashPassword password, @password_salt
  @save callback

# @param callback(err)
Account.methods.incBalance = (amount, type, payload, callback) ->
  unless _.isNumber amount
    return callback 'invalid_amount'

  financials = new models.Financials
    account_id: @_id
    type: type
    amount: amount
    payload: payload

  financials.validate (err) =>
    return callback err if err

    @update
      $inc:
        balance: amount
    , (err) ->
      return callback err if err

      financials.save (err) ->
        callback err

Account.methods.inGroup = (group) ->
  return group in @groups

Account.methods.inPlan = (plan_name) ->
  return plan_name in _.keys @plans

Account.methods.createSecurityLog = (type, token, payload, callback) ->
  SecurityLog.create
    account_id: @_id
    type: type
    token: _.pick token, 'type', 'token', 'created_at', 'payload'
    payload: payload
  , callback

Account.methods.getComponents = (type, callback) ->
  if _.isArray type
    query =
      type:
        $in: type
  else if _.isString type
    query =
      type: type
  else
    query = {}

  Component.find query, (err, components) ->
    callback components

Account.methods.getAvailableComponentsTypes = ->
  return _.compact _.map _.keys(@plans), (plan_name) ->
    return _.keys Plan.get(plan_name).available_components

# callback(err)
Account.methods.joinPlan = (plan_name, callback) ->
  plan = billing.plans[plan_name]

  modifier =
    $set: {}

  modifier.$set["plans.#{plan.name}"] =
    billing_state:
      time:
        expired_at: new Date()

  plan.triggerBilling @, =>
    app.models.Account.findByIdAndUpdate @_id, modifier, (err, account) ->
      async.each _.keys(plan.available_components), (component_type, callback) =>
        plan_component_info = plan.available_components[component_type]
        component_type = pluggable.components[component_type]

        unless plan_component_info.default
          return callback()

        async.each plan_component_info.default, (defaultInfo, callback) ->
          default_info = defaultInfo account

          component_type.createComponent account,
            physical_node: default_info.physical_node
            name: default_info.name ? ''
            payload: default_info
          , callback

      , callback

# callback(err)
Account.methods.leavePlan = (plan_name, callback) ->
  plan = billing.plans[plan_name]

  modifier =
    $unset: {}

  modifier.$unset["plans.#{plan.name}"] = true

  plan.triggerBilling @, =>
    app.models.Account.findByIdAndUpdate @_id, modifier, (err, account) ->
      available_component_types = account.getAvailableComponentsTypes()

      account.getComponents null, (components) ->
        async.each components, (component, callback) ->
          if component.component_type in available_component_types
            return callback()

          component_type = ComponentType.get component.component_type
          component_type.destroyComponent component, callback

        , callback

# @param callback(err, account)
Account.methods.leaveAllPlans = (callback) ->
  async.each @plans, (plan_name, callback) =>
    @leavePlan plan_name, callback
  , (err) =>
    return callback err if err
    Account.findById @_id, callback

_.extend app.models,
  Account: mongoose.model 'Account', Account
