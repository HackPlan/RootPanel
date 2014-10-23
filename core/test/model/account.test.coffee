utils = null
Account = null

test_account = null
created_account_ids = []

describe 'model/account', ->
  before ->
    require '../../../app'
    {utils} = app
    {Account} = app.models

  after (done) ->
    Account.remove
      _id:
        $in: created_account_ids
    , done

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

        created_account_ids.push account._id
        test_account = account

        done()

  describe 'search', ->
    it 'should work with username', (done) ->
      Account.search test_account.username, (result) ->
        result.email.should.be.equal test_account.email
        done()

    it 'should work with email', (done) ->
      Account.search test_account.email, (result) ->
        result.username.should.be.equal test_account.username
        done()

    it 'should work with id', (done) ->
      Account.search test_account.id, (result) ->
        result.username.should.be.equal test_account.username
        done()

    it 'should not exist', (done) ->
      Account.search 'username_not_exist', (result) ->
        expect(result).to.not.exist
        done()
