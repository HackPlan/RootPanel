describe 'billing', ->
  billing = null
  Account = null

  account = null

  before ->
    {billing} = app
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
      account.billing.services = ['sample']
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
    it 'pending'

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
