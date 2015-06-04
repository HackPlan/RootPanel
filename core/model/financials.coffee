Mabolo = require 'mabolo'
Q = require 'q'

{ObjectID} = Mabolo

###
  Model: Financials.
###
module.exports = Financials = Mabolo.model 'Financials',
  # Public: Related account
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  # Public: Type of financial
  type:
    required: true
    type: String
    enum: ['deposit', 'billing']

  # Public: status of financial
  status:
    type: String
    enum: ['pending', 'rejected', 'canceled', 'success', 'processing']

  # Public: Amount, always positive value
  amount:
    required: true
    type: Number

  # Public: Custom options of financial
  options:
    type: Object
    default: -> {}

  created_at:
    type: Date
    default: -> new Date()

Account = require './account'

###
  Public: Create financial log.

  * `account` {Account}
  * `type` {String}
  * `amount` {Number}
  * `options` (optional) {Object}

  Return {Promise} resolve with created financial.
###
Financials.createLog = ({_id}, type, amount, options) ->
  @create
    account_id: _id
    type: type
    amount: Math.abs amount
    options: options

###
  Public: Get deposit logs of specified account.

  * `account` {Account}
  * `options` (optional) {Object}

    * `req` {ClientRequest}
    * `limit` {Number} Default to 30.

  Return {Promise} resolve with array of {Financials}.
###
Financials.getDepositLogs = ({_id}, {req, limit} = {}) ->
  @find(
    account_id: _id
    type: 'deposit'
  ,
    sort:
      created_at: -1
    limit: limit ? 30
  ).then (financials) ->
    Q.all financials.map (financial) ->
      provider = root.paymentProviders.byName financial.options.provider

      if provider
        provider.populateFinancials req, financial
      else
        return financial

###
  Public: Get billing logs of specified account.

  * `account` {Account}
  * `options` (optional) {Object}

    * `limit` {Number} Default to 30.

  Return {Promise} resolve with array of {Financials}.
###
Financials.getBillingLogs = ({_id}, {limit} = {}) ->
  @find
    account_id: _id
    type: 'billing'
  ,
    sort:
      created_at: -1
    limit: limit ? 30

###
  Public: Create deposit request for specified account.

  * `account` {Account}
  * `financial` {Object}

    * `amount` {Number}
    * `provider` {PaymentProvider} TODO: Verify provider
    * `order_id` (optional) {String}

  Return {Promise} resolve with created {Financials}.
###
Financials.createDepositRequest = (account, {amount, provider, order_id}) ->
  @create
    account_id: account._id
    type: 'deposit'
    status: 'pending'
    amount: amount
    options:
      provider: provider.name
      order_id: order_id

###
  Public: Update status of financial.

  * `status` {String} New status.

  Return {Promise}.
###
Financials::updateStatus = (status) ->
  updateDepositStatus = =>
    if @status != status
      Financials.findOneAndUpdate
        _id: @_id
        status: @status
      ,
        status: status
      .tap (result) =>
        if result?.status == 'success'
          @populate().then =>
            @account.increaseBalance @amount

  switch @type
    when 'deposit'
      return updateDepositStatus()
    else
      throw new Error "cant update status for `#{@type}` type"

###
  Public: Populate refs accounts.

  This function will populate following fields:

  * `account`: {Account} from `account_id`.

  Return {Promise}.
###
Financials::populate = ->
  Account.findById(@account_id).then (account) =>
    return _.extend @,
      account: account
