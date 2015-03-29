{utils, config, models, mabolo} = app
{_, async} = app.libs
{Financial, SecurityLog, Component} = app.models
{ObjectID} = mabolo

billing = require '../billing'

process.nextTick ->
  {Financial, SecurityLog, Component} = app.models

Token = mabolo.model 'Token',
  type:
    required: true
    type: String

  code:
    required: true
    type: String

  payload:
    type: Object

  created_at:
    required: true
    type: Date
    default: -> new Date()

  updated_at:
    required: true
    type: Date
    default: -> new Date()

Account = mabolo.model 'Account',
  username:
    required: true
    type: String
    regex: utils.rx.username

  email:
    required: true
    type: String
    regex: utils.rx.email

  groups: [String]
  tokens: [Token]

  password:
    type: String

  password_salt:
    type: String

  preferences:
    type: Object

  plans:
    type: Object

  balance:
    type: Number
    default: 0

  arrears_at:
    type: Date

  pluggable:
    type: Object

  resources_limit:
    type: Object

  created_at:
    required: true
    type: Date
    default: -> new Date()

Token::revoke = ->
  @parent().update
    $pull:
      tokens:
        code: @code

Account.ensureIndex

Account.register = ({username, email, password}) ->
  password_salt = utils.randomSalt()
  password = utils.hashPassword password, password_salt

  avatar_url = '//cdn.v2ex.com/gravatar/' + utils.md5(email)

  account = new Account
    email: email
    username: username
    password: password
    password_salt: password_salt

    preferences:
      avatar_url: avatar_url
      language: 'auto'
      timezone: config.i18n.default_timezone

    plans: {}
    pluggable: {}

  app.applyHooks('account.before_register',
    execute: 'filter'
  ).then ->
    account.save()

Account.search = (identification) ->
  @findOne(username: identification).then (account) =>
    if account
      return account
    else
      return @findOne(email: identification).then (account) =>
        if account
          return account
        else
          return @findById identification

Account.authenticate = (token_code) ->
  @findOneAndUpdate(
    'tokens.token': token_code
  ,
    $set:
      'tokens.$.updated_at': new Date()

  ).then (account) ->
    return {
      account: account

      token: _.findWhere account?.tokens,
        code: token_code
    }

Account::createToken = (type, payload) ->
  token = new Token
    type: type
    code: utils.randomSalt()
    payload: payload
    created_at: new Date()
    updated_at: new Date()

  @update(
    $push:
      tokens: token
  ).thenResolve token

Account::matchPassword = (password) ->
  return @password == utils.hashPassword(password, @password_salt)

Account::setPassword = (password) ->
  password_salt = utils.randomSalt()
  password = utils.hashPassword password, password_salt

  @update
    $set:
      password: password
      password_salt: password_salt

Account::setEmail = (email) ->

Account::updatePreferences = (preferences) ->

Account::increaseBalance = (amount, type, payload) ->
  Financials.createLog(@, type, amount, payload).then =>
    @update
      $inc:
        balance: amount

Account::inGroup = (group) ->
  return group in @groups

Account::isAdmin = ->
  return @inGroup 'root'

Account::inPlan = (plan_name) ->
  return plan_name in _.keys @plans

Account::availableComponentsTemplates = ->
  return _.uniq _.flatten _.compact _.map _.keys(@plans), (plan_name) ->
    return _.keys app.plans[plan_name].available_components

Account::populate = ->
  Component.getComponents(@).then (components) =>
    return _.extend @,
      components: components
