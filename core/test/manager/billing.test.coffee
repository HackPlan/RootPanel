{createAccount} = helpers

describe 'manager.billing', ->
  describe 'addMember and removeMember', ->
    account = null
    plan = root.billing.byName 'sample'

    before ->
      createAccount().then (result) ->
        account = result

    it '::addMember', ->
      plan.addMember account

    it '::hasMember', ->
      plan.hasMember(account).should.be.true

    it '::removeMember', ->
      plan.removeMember(account).then ->
        plan.hasMember(account).should.be.false
