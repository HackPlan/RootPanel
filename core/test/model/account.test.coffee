utils = null
Account = null

describe 'model/account', ->
  before ->
    require '../../../app'
    {utils} = app
    {Account} = app.models

  describe 'validators should be work', ->
    it 'invalid_email', (done) ->
      account = new Account
        username: 'jysperm'
        email: 'invalid_email'

      account.save (err) ->
        utils.pickErrorName(err).should.be.equal 'invalid_email'
        done()

    it 'invalid_username', (done) ->
      account = new Account
        username: 'X'
        email: 'jysperm@gmail.com'

      account.save (err) ->
        utils.pickErrorName(err).should.be.equal 'invalid_username'
        done()
