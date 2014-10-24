express = require 'express'

Account = null
middleware = null

describe 'middleware', ->
  before ->
    require '../../app'
    {middleware} = app
    {Account} = app.models

  describe 'errorHandling', ->
    it 'should work', (done) ->
      server = express()
      server.use middleware.errorHandling()

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


