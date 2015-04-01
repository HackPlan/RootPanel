Q = require 'q'

{mabolo} = app
{ObjectID} = mabolo

Financials = mabolo.model 'Financials',
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  type:
    required: true
    type: String
    enum: ['deposit', 'billing']

  status:
    type: String
    enum: ['pending', 'rejected', 'canceled', 'success', 'processing']

  amount:
    required: true
    type: Number

  created_at:
    type: Date
    default: -> new Date()

  options:
    type: Object

Financials.createLog = (account, type, amount, options) ->
  @create
    account_id: account._id
    type: type
    amount: Math.abs amount
    options: options

Financials.getDepositLogs = (account, {req, limit}) ->
  @find(
    account_id: account._id
    type: 'deposit'
  ,
    sort:
      created_at: -1
    limit: limit
  ).then (financials) ->
    Q.all financials.map (financial) ->
      provider = app.extends.payments.byName financial.payload.provider

      if provider
        provider.populateFinancials req, financial
      else
        return financial

Financials.getBillingLogs = (account, {limit}) ->
  @find
    account_id: account._id
    type: 'billing'
  ,
    sort:
      created_at: -1
    limit: limit

Financials.createDepositRequest = (account, {amount, provider, order_id}) ->
  @create
    account_id: account._id
    type: 'deposit'
    status: 'pending'
    amount: amount
    options:
      provider: provider
      order_id: order_id

Financials::updateStatus = (status) ->
  updateDepositStatus = =>
    if @status == status
      return

    Financials.findOneAndUpdate(
      _id: @_id
      status: @status
    ,
      status: status
    ).then (result) =>
      unless result
        return

      if status == 'success'
        @populate().then ->
          @account.increaseBalance @amount

  if @type == 'deposit'
    updateDepositStatus()
  else
    throw new Error "cant update status for `#{@type}` type"

Financials::populate = ->
  Account.findById(@account_id).then (account) =>
    @account = account
