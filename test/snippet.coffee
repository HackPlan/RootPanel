global.utils = require '../core/utils'

createAgent = (callback) ->
  agent = supertest.agent app.express

  agent.get '/account/session_info'
  .end (err, res) ->
    callback err,
      agent: agent
      csrf_token: res.body.csrf_token

cleanUpByAccount = ({account_id}, callback) ->
  app.models.Account.findByIdAndRemove account_id, callback

createLoggedAgent = (callback) ->
  createAgent (err, {agent, csrf_token}) ->
    username = 'test' + utils.randomString(8).toLowerCase()
    email = utils.randomString(8) + '@gmail.com'
    password = utils.randomString 8

    agent.post '/account/register'
    .send
      csrf_token: csrf_token
      username: username
      email: email
      password: password
    .end (err, res) ->
      after (done) ->
        cleanUpByAccount res.body.account_id, done

      callback err,
        agent: agent
        username: username
        email: email
        password: password
        csrf_token: csrf_token
        account_id: res.body.account_id

_.extend global,
  createAgent: createAgent
  cleanUpByAccount: cleanUpByAccount
  createLoggedAgent: createLoggedAgent
