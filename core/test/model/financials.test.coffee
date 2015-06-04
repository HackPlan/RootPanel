describe 'model.financials', ->
  Account = require '../../model/account'
  Financials = require '../../model/financials'

  {PaymentProvider} = require root.resolve 'core/registry/payment-provider'
  provider = new PaymentProvider name: 'taobao'

  describe '.createLog', ->
    it 'should success', ->
      createAccount().then (account) ->
        Financials.createLog(account, 'billing', 10).then (log) ->
          Financials.getBillingLogs(account).then (logs) ->
            _.findWhere(logs,
              type: 'billing'
              amount: 10
            ).should.be.exists

  describe '.createDepositRequest', ->
    it 'should success', ->
      createAccount().then (account) ->
        Financials.createDepositRequest(account,
          amount: 20
          provider: provider
        ).then (deposit) ->
          deposit.status.should.be.equal 'pending'
          deposit.options.provider.should.be.equal 'taobao'

  describe '::updateStatus', ->
    deposit = null

    beforeEach ->
      createAccount().then (account) ->
        Financials.createDepositRequest(account,
          amount: 20
          provider: provider
        ).then (log) ->
          deposit = log

    it 'pending -> success', ->
      deposit.updateStatus('success').then ->
        Account.findById(deposit.account_id).then ({balance}) ->
          balance.should.be.equal 20

    it 'pending -> rejected', ->
      deposit.updateStatus('rejected').then ->
        Account.findById(deposit.account_id).then ({balance}) ->
          balance.should.be.equal 0
