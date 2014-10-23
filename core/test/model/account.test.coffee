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

  describe 'register', ->
    it 'should success', (done) ->
      username = "test#{utils.randomString(20).toLowerCase()}"
      email = "#{utils.randomString 20}@gmail.com"
      password = utils.randomString 20

      Account.register
        username: username
        email: email
        password: password
      , (err, account) ->
        expect(err).to.not.exist

        account.username.should.be.equal username
        account.email.should.be.equal email.toLowerCase()
        account.password.should.have.length 64

        done()
