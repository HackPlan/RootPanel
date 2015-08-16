{createAdminAgent} = helpers

describe 'router.admin', ->
  agent = createAdminAgent()

  it 'GET /admin/dashboard', ->
    agent.get '/admin/dashboard'
