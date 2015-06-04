request = require 'request'
chai = require 'chai'
_ = require 'lodash'
Q = require 'q'

utils = require '../core/utils'
createAgent = require './agent'

expect = chai.expect

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

createAccount = ->
  root.Account.register randomAccount()

createAdmin = ->
  root.Account.register(randomAccount()).then (account) ->
    account.joinGroup 'root'

createLoggedAgent = (options) ->
  ready = null
  agent = {}

  createAgent.methods.map (method) ->
    agent[method] = (args...) ->
      ready ?= createAgent().post '/account/register',
        json: randomAccount()

      ready.then ({body}) ->
        options ?= {}
        options.headers ?= {}
        options.headers.token = body.token
        createAgent(options)[method] args...

  return agent

module.exports = {
  _
  Q
  chai
  utils
  expect

  ifEnabled
  unlessTravis

  randomAccount
  createAdmin
  createAccount
  createAgent
  createLoggedAgent
}
