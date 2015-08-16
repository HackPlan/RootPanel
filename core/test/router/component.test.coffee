{createLoggedAgent} = helpers
{Account, Component} = root

describe 'router.component', ->
  agent = createLoggedAgent
    baseUrl: '/components'

  component_id = null

  before ->
    {BillingPlan} = require '../../billing-manager'

    root.billing.plans['sample'].components['built-in.sample'] = {}

    agent.ready.then ->
      Account.search(agent.account.username).then (account) ->
        root.billing.byName('sample').addMember account

  it 'POST /:type', ->
    agent.post '/built-in.sample',
      json:
        name: 'test component'
    .then ({body}) ->
      body.type.should.be.equal 'built-in.sample'
      body.status.should.be.equal 'running'
      component_id = body._id

  it 'DELETE /:id', ->
    agent.delete("/#{component_id}").then ->
      Component.findById(component_id).then (component) ->
        expect(component).to.not.exists
