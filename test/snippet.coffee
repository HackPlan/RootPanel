utils = require '../core/utils'

createAgent = (callback) ->
  agent = supertest.agent app.express

  agent.get '/account/session_info'
  .end (err, res) ->
    callback err,
      agent: agent
      csrf_token: res.body.csrf_token

createLoggedAgent = (callback) ->
  createAgent (err, {agent, csrf_token}) ->
    username = 'test' + utils.randomString(10).toLowerCase()
    email = utils.randomString(10) + '@gmail.com'
    password = utils.randomString 10

    agent.post '/account/register'
    .send
      csrf_token: csrf_token
      username: username
      email: email
      password: password
    .end (err, res) ->
      callback err,
        agent: agent
        username: username
        email: email
        password: password
        csrf_token: csrf_token
        account_id: res.body.account_id

_.extend global,
  createAgent: createAgent
  createLoggedAgent: createLoggedAgent
