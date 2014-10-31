describe 'billing', ->
  billing = null
  config = null
  Account = null

  account = null

  before ->
    {billing, config} = app
    {Account} = app.models

    account = new Account
      username: 'billing'
      email: 'billing@gmail.com'
      billing:
        services: []
        plans: []
        last_billing_at: {}
        balance: 0
        arrears_at: new Date

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
      config.plans.billing_test =
        billing_by_time:
          unit: 24 * 3600 * 1000
          price: 10 / 30

        services: []
        resources: {}

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

  describe 'triggerBilling', ->
    it 'pending'

  describe 'joinPlan', ->
    it 'pending'

  describe 'leavePlan', ->
    it 'pending'

  describe 'forceLeaveAllPlans', ->
    it 'pending'

  describe 'calcResourcesLimit', ->
    it 'pending'
