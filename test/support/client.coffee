request = require 'request'

exports.get = (url, options, callback) ->
  options = deepmerge module.exports.default_options, options

  options = deepmerge options,
    uri: "http://127.0.0.1:#{app.config.web.listen}#{options.uri_prefix ? ''}#{url}"

  request options, (err, res, body) ->
    throw err if err

    if options.expect_status_code
      res.statusCode.should.equal options.expect_status_code

    if options.response_json
      body = JSON.parse body

    this.err = err
    this.res = res
    this.body = body
    this.options = options

    callback.apply this, [err, res, body]

exports.post = (url, options, callback) ->
  options.method = 'POST'
  return exports.get url, options, callback

exports.defaultOptions = (options) ->
  default_options =
    followRedirect: false
    uri_prefix: '/'
    expect_status_code: 200
    response_json: true

  exports.default_options = deepmerge default_options, options

exports.default_options = {}
