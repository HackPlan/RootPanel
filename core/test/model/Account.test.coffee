after (done) ->
  app.models.Financials.remove
    account_id:
      $in: created_objects.accounts
  , done

after (done) ->
  app.models.Account.remove
    _id:
      $in: created_objects.accounts
  , done

describe 'model/Account', ->
  utils = null
  Account = null
  Financials = null

  account = null
  password = null
  token = null

  before ->
    {utils} = app
    {Account, Financials} = app.models

  after ->
    namespace.accountModel =
      account: account

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
      , (err, created_account) ->
        expect(err).to.not.exist
        account = created_account

        account.username.should.be.equal username
        account.email.should.be.equal email.toLowerCase()
        account.password.should.have.length 64

        created_objects.accounts.push account._id

        done()

  describe 'search', ->
    it 'should work with username', (done) ->
      Account.search account.username, (account) ->
        account.email.should.be.equal account.email
        done()

    it 'should work with email', (done) ->
      Account.search account.email, (account) ->
        account.username.should.be.equal account.username
        done()

    it 'should work with id', (done) ->
      Account.search account.id.toString(), (account) ->
        account.username.should.be.equal account.username
        done()

    it 'should not exist', (done) ->
      Account.search 'username_not_exist', (account) ->
        expect(account).to.not.exist
        done()

  describe 'generateToken', ->
    it 'should success', (done) ->
      Account.generateToken (token1) ->
        Account.generateToken (token2) ->
          token1.should.not.equal token2
          token1.should.have.length 64
          done()

  describe 'createToken', ->
    it 'should success', (done) ->
      account.createToken 'full_access', {}, (err, created_token) ->
        created_token.should.be.exist

        Account.findById account._id, (err, account) ->
          matched_token = _.findWhere account.tokens,
            token: created_token.token

          matched_token.should.be.exist
          token = created_token.token
          done()

    it 'should fail with invalid type', (done) ->
      account.createToken 'invalid_type', {}, (err) ->
        err.should.be.exist
        done()

  describe 'authenticate', ->
    it 'should success', (done) ->
      Account.authenticate token, (returned_token, account) ->
        returned_token.token.should.equal token
        account.id.should.equal account.id

        done()

    it 'should fail with no token', (done) ->
      Account.authenticate '', (token, account) ->
        expect(token).to.not.exist
        expect(account).to.not.exist

        done()

    it 'should fail with invalid token', (done) ->
      Account.authenticate 'invalid token', (token, account) ->
        expect(token).to.not.exist
        expect(account).to.not.exist

        done()

  describe 'matchPassword', ->
    it 'should be matched', ->
      account.matchPassword(password).should.be.ok

    it 'should not matched', ->
      account.matchPassword('wrong_password').should.not.ok

  describe 'updatePassword', ->
    it 'should success', (done) ->
      old_password = password
      password = utils.randomString 20

      account.updatePassword password, ->
        Account.findById account._id, (err, account) ->
          account.matchPassword(password).should.be.ok
          account.matchPassword(old_password).should.not.ok
          done()

  describe 'incBalance', ->
    it 'should success', (done) ->
      account.incBalance -10, 'deposit', {meta: 'meta'}, (err) ->
        Financials.findOne
          account_id: account._id
        , (err, financials) ->
          financials.amount.should.be.equal -10
          financials.payload.meta.should.be.equal 'meta'

          Account.findById account._id, (err, account) ->
            account.billing.balance.should.be.equal -10
            done()

    it 'should fail with invalid amount', (done) ->
      account.incBalance '10', 'deposit', {}, (err) ->
        err.should.be.exist
        done()

    it 'should fail with invalid type', (done) ->
      account.incBalance -10, 'invalid_type', {}, (err) ->
        err.should.be.exist
        done()

  describe 'inGroup', ->
    it 'should in it', ->
      account.groups = ['test']
      account.inGroup('test').should.be.ok

    it 'should not in it', ->
      account.inGroup('group_not_exist').should.not.ok

  describe 'createSecurityLog', ->
    it 'pending'

describe 'model/Token', ->
  Account = null

  account = null

  before ->
    account = namespace.accountModel.account
    {Account} = app.models

  describe 'validators should be work', ->
    it 'unique_validation_error'

  describe 'revoke', ->
    it 'should success', (done) ->
      account.createToken 'full_access', {}, (err, token) ->
        Account.findById account._id, (err, account) ->
          matched_token = _.findWhere account.tokens,
            token: token.token

          matched_token.revoke ->
            Account.findById account._id, (err, account) ->
              matched_token = _.findWhere account.tokens,
                token: token.token

              expect(matched_token).to.not.exist

              done()
