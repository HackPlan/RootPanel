utils = null
Account = null
Financials = null

util =
  account: null
  password: null

  created_account_ids: []

describe 'model/account', ->
  before ->
    require '../../../app'
    {utils} = app
    {Account, Financials} = app.models

  after (done) ->
    Financials.remove
      account_id:
        $in: util.created_account_ids
    , done

  after (done) ->
    Account.remove
      _id:
        $in: util.created_account_ids
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
      util.password = utils.randomString 20

      Account.register
        username: username
        email: email
        password: util.password
      , (err, account) ->
        expect(err).to.not.exist

        account.username.should.be.equal username
        account.email.should.be.equal email.toLowerCase()
        account.password.should.have.length 64

        util.created_account_ids.push account._id
        util.account = account

        done()

  describe 'search', ->
    it 'should work with username', (done) ->
      Account.search util.account.username, (account) ->
        account.email.should.be.equal util.account.email
        done()

    it 'should work with email', (done) ->
      Account.search util.account.email, (account) ->
        account.username.should.be.equal util.account.username
        done()

    it 'should work with id', (done) ->
      Account.search util.account.id, (account) ->
        account.username.should.be.equal util.account.username
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
      util.account.createToken 'full_access', {}, (err, token) ->
        token.should.be.exist

        Account.findById util.account._id, (err, account) ->
          matched_token = _.findWhere account.tokens,
            token: token.token

          matched_token.should.be.exist
          done()

    it 'should fail with invalid type', (done) ->
      util.account.createToken 'invalid_type', {}, (err) ->
        err.should.be.exist
        done()

  describe 'matchPassword', ->
    it 'should be matched', ->
      util.account.matchPassword(util.password).should.be.ok

    it 'should not matched', ->
      util.account.matchPassword('wrong_password').should.not.ok

  describe 'updatePassword', ->
    it 'should success', (done) ->
      old_password = util.password
      util.password = utils.randomString 20

      util.account.updatePassword util.password, ->
        Account.findById util.account._id, (err, account) ->
          account.matchPassword(util.password).should.be.ok
          account.matchPassword(old_password).should.not.ok
          done()

  describe 'incBalance', ->
    it 'should success', (done) ->
      util.account.incBalance -10, 'deposit', {meta: 'meta'}, (err) ->
        Financials.findOne
          account_id: util.account._id
        , (err, financials) ->
          financials.amount.should.be.equal -10
          financials.payload.meta.should.be.equal 'meta'

          Account.findById util.account._id, (err, account) ->
            account.billing.balance.should.be.equal -10
            done()

    it 'should fail with invalid amount', (done) ->
      util.account.incBalance '10', 'deposit', {}, (err) ->
        err.should.be.exist
        done()

    it 'should fail with invalid type', (done) ->
      util.account.incBalance -10, 'invalid_type', {}, (err) ->
        err.should.be.exist
        done()

  describe 'inGroup', ->
    it 'should in it', ->
      util.account.groups = ['test']
      util.account.inGroup('test').should.be.ok

    it 'should not in it', ->
      util.account.inGroup('group_not_exist').should.not.ok
