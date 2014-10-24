express = require 'express'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'

Account = null
middleware = null

describe 'middleware', ->
  before ->
    require '../../app'
    {middleware} = app
    {Account} = app.models

  describe 'errorHandling', ->
    it 'should work with param', (done) ->
      server = express()
      server.use middleware.errorHandling

      server.use (req, res) ->
        res.error 'error_name',
          message: 'error_message'

      supertest server
      .get '/'
      .expect 400
      .expect (res) ->
        res.body.error.should.be.equal 'error_name'
        res.body.message.should.be.equal 'error_message'
        return null
      .end done

    it 'should work with status code', (done) ->
      server = express()
      server.use middleware.errorHandling

      server.use (req, res) ->
        res.error 'error_name', null, 403

      supertest server
      .get '/'
      .expect 403
      .expect (res) ->
        res.body.error.should.be.equal 'error_name'
        return null
      .end done

  describe 'session', ->
    it 'session should be available', (done) ->
      server = express()
      server.use middleware.session()

      server.use (req, res, next) ->
        req.session.should.be.exist
        req.session.test_field = 'test_value'
        next()

      server.use (req, res) ->
        req.session.test_field.should.be.equal 'test_value'
        res.send()

      supertest server
      .get '/'
      .expect 200
      .end done

  describe 'csrf', ->
    server = express()
    agent = supertest.agent server
    token = null

    before ->
      server.use bodyParser.json()
      server.use cookieParser()
      server.use middleware.session()
      server.use middleware.errorHandling
      server.use middleware.csrf()

      server.use (req, res) ->
        req.session.csrf_token.should.be.exist
        res.json
          csrf_token: req.session.csrf_token

    it 'should ignore GET request', (done) ->
      agent.get '/'
      .expect 200
      .end (err, res) ->
        token = res.body.csrf_token
        done()

    it 'should reject with no token', (done) ->
      agent.post '/'
      .expect 403
      .end done

    it 'should success with token', (done) ->
      agent.post '/'
      .send
        csrf_token: token
      .expect 200
      .end done

  describe 'authenticate', ->
    it 'pending'

  describe 'accountHelpers', ->
    it 'pending'

  describe 'requireAuthenticate', ->
    it 'pending'

  describe 'requireAdminAuthenticate', ->
    it 'pending'

  describe 'requireInService', ->
    it 'pending'
