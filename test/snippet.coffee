supertest = require 'supertest'
request = require 'request'
chai = require 'chai'
url = require 'url'
_ = require 'lodash'
Q = require 'q'

expect = chai.expect

chai.should()
chai.config.includeStack = true

utils = require '../core/utils'

ifEnabled = (name) ->
  if name in _.keys config.plugins
    return describe
  else
    return describe.skip

unlessTravis = ->
  unless process.env.TRAVIS == 'true'
    return describe
  else
    return describe.skip

randomAccount = ->
  randomLowerCase = ->
    utils.randomString(arguments...).toLowerCase()

  return {
    username: 'test' + randomLowerCase(6)
    password: utils.randomString 8
    email: 'test' + randomLowerCase(6) + '@gmail.com'
  }

createAgent = (agent_options = {}) ->
  methods = ['get', 'post', 'delete', 'put', 'patch', 'head', 'options']

  if _.isNumber config.web.listen
    prefix = "http://127.0.0.1:#{config.web.listen}"
  else
    prefix = "http://unix:#{config.web.listen}:"

  agent = {}

  methods.map (method) ->
    agent[method] = (url, options = {}, asserts = {}) ->
      options = _.extend
        url: url
        json: true
        method: method
        followRedirect: false
      , options, agent_options

      if options.baseUrl
        options.baseUrl = prefix + options.baseUrl

      Q.Promise (resolve, reject) ->
        request options, (err, res, body) ->
          if err
            reject err
          else
            resolve res
      .tap (res) ->
        {status, headers, body, error} = asserts

        message = printHttpResponse res

        if status
          expect(res.statusCode).to.equal status, message
        else if !error
          expect(res.statusCode).to.within 200, 300, message

        if error
          expect(res.body.error).to.equal error, message

        assertObjectFields = (data, asserts) ->
          for field, pattern of asserts ? {}
            if pattern instanceof RegExp
              expect(data[field]).to.match pattern
            else
              expect(data[field]).to.equal pattern

        assertObjectFields res.headers, headers
        assertObjectFields res.body, body

  return agent

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

printHttpResponse = ({httpVersion, statusCode, statusMessage, headers, body}) ->
  message = """
    Response:
    HTTP/#{httpVersion} #{statusCode} #{statusMessage}\n
  """

  for name, value of headers
    message += "#{name}: #{value}\n"

  if headers['content-type']?.match /text\/html/
    body = body.replace /&nbsp;/g, ' '
    body = body.replace /<br>/g, '\n'

  message += "\n#{body}"

  return message

_.extend global, {
  supertest
  utils

  ifEnabled
  unlessTravis
  randomAccount

  createAgent
  cleanUpByAccount
  createLoggedAgent
}
