request = require 'request'
chai = require 'chai'
_ = require 'lodash'
Q = require 'q'

expect = chai.expect

methods = ['get', 'post', 'delete', 'put', 'patch', 'head', 'options']

module.exports = createAgent = (agent_options) ->
  if _.isNumber config.web.listen
    prefix = "http://127.0.0.1:#{config.web.listen}"
  else
    prefix = "http://unix:#{config.web.listen}:"

  agent = {}

  methods.forEach (method) ->
    agent[method] = (url, options, asserts) ->
      options = _.merge
        url: url
        json: true
        method: method
        followRedirect: false
      , options, agent_options

      if options.baseUrl
        options.baseUrl = prefix + options.baseUrl
      else
        options.baseUrl = prefix + '/'

      Q.nfcall(request, options).then ([res]) ->
        return res
      .tap (res) ->
        {status, headers, body, error} = asserts ? {}

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
              expect(data[field]).to.match pattern, message
            else
              expect(data[field]).to.equal pattern, message

        assertObjectFields res.headers, headers
        assertObjectFields res.body, body

  return agent

module.exports.methods = methods

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
  else if headers['content-type']?.match /application\/json/
    body = JSON.stringify body, null, '  '

  message += "\n#{body}"

  return message
