{createAdminAgent} = helpers

describe 'router.admin', ->
  agent = null

  before ->
    agent = createAdminAgent()

  it 'GET /admin/dashboard', ->
    agent.get '/admin/dashboard'
