describe 'billing', ->
  billing = null
  config = null

  Account = null
  Financials = null

  account = null

  before ->
    {billing, config} = app
    {Account, Financials} = app.models

    account = new Account
      username: 'billing'
      email: 'billing@gmail.com'
      billing:
        services: []
        plans: []
        last_billing_at: {}
        balance: 0
        arrears_at: null

    config.plans.billing_test =
      billing_by_time:
        unit: 24 * 3600 * 1000
        price: 10 / 30

      services: []
      resources:
        cpu: 144
        storage: 520
        transfer: 39
        memory: 27

    config.plans.billing_test2 =
      resources:
        cpu: 50
        storage: 200
        memory: 10

  describe 'isForceFreeze', ->
    it 'should be false when not in any services', ->
      expect(billing.isForceFreeze(account)).to.not.ok

    it 'should be true when balance below then 0', ->
      account.billing.plans = ['sample']
      account.billing.balance = -5
      expect(billing.isForceFreeze(account)).to.be.ok

    it 'should be true when arrears at 1 month ago', ->
      account.billing.balance = 5
      account.billing.arrears_at = new Date Date.now() - 30 * 24 * 3600 * 1000
      expect(billing.isForceFreeze(account)).to.be.ok

    it 'should be false', ->
      account.billing.arrears_at = null
      expect(billing.isForceFreeze(account)).to.not.ok

  describe 'generateBilling', ->
    it 'should success for billing_by_time plan', (done) ->
      last_billing_at = new Date Date.now() - 2 * 24 * 3600 * 1000 + 5000000

      account.plan = ['billing_test']
      account.billing.last_billing_at =
        billing_test: last_billing_at

      billing.generateBilling account, 'billing_test', (billing_report) ->
        new_last_billing_at = new Date last_billing_at.getTime() + 2 * 24 * 3600 * 1000

        billing_report.should.eql
          plan_name: 'billing_test'
          billing_unit_count: 2
          last_billing_at: new_last_billing_at
          amount_inc: -10 / 15

        new_last_billing_at.should.above new Date()
        new_last_billing_at.should.below new Date Date.now() + 24 * 3600 * 1000

        done()

    it 'should return null when less then unit', (done) ->
      account.billing.last_billing_at =
        billing_test: new Date Date.now() + 5000000

      billing.generateBilling account, 'billing_test', (billing_report) ->
        expect(billing_report).to.not.exist
        done()

  describe 'calcResourcesLimit', ->
    it 'should success', ->
      billing.calcResourcesLimit(['billing_test', 'billing_test2']).should.eql
        cpu: 194
        storage: 720
        transfer: 39
        memory: 37

  describe 'triggerBilling', ->
    last_billing_at = new Date Date.now() - 2 * 24 * 3600 * 1000 + 5000000
    new_last_billing_at = new Date last_billing_at.getTime() + 2 * 24 * 3600 * 1000

    before (done) ->
      account.billing =
        services: []
        plans: ['billing_test']
        last_billing_at:
          billing_test: last_billing_at
        balance: 10
        arrears_at: null

      created_objects.accounts.push account._id

      account.save done

    it 'should success', (done) ->
      billing.triggerBilling account, (new_account) ->
        account = new_account
        account.billing.last_billing_at.billing_test.getTime().should.equal new_last_billing_at.getTime()
        account.billing.balance.should.be.equal 10 - 10 / 15

        Financials.findOne
          account_id: account._id
          type: 'billing'
        , (err, financials) ->
          financials.amount.should.be.equal -10 / 15
          financials.payload.billing_test.billing_unit_count.should.be.equal 2
          done()

    it 'should not create billing when range less then unit', (done) ->
      billing.triggerBilling account, (account) ->
        Financials.find
          account_id: account._id
          type: 'billing'
        , (err, financials) ->
          financials.should.have.length 1
          done()

  describe 'forceLeaveAllPlans', ->
    it 'should success', (done) ->
      billing.forceLeaveAllPlans account, (new_account) ->
        account = new_account
        account.billing.plans.should.have.length 0
        done()

  describe 'joinPlan', ->
    it 'should success', (done) ->
      billing.joinPlan {}, account, 'billing_test', ->
        Account.findById account._id, (err, new_account) ->
          account = new_account
          account.billing.plans.should.have.length 1
          done()

  describe 'leavePlan', ->
    it 'should success', (done) ->
      billing.leavePlan {}, account, 'billing_test', ->
        Account.findById account._id, (err, new_account) ->
          new_account.billing.plans.should.have.length 0
          done()
