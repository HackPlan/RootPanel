describe 'model.account', ->
  Account = require '../../model/account'

  describe '.register', ->
    it 'should success', ->
      {username, email, password} = randomAccount()

      Account.register({username, email, password}).then (account) ->
        account.username.should.be.equal username

  describe '.search', ->
    {id, email, username} = {}

    before ->
      createAccount().then (account) ->
        {_id: id, email, username} = account

    it 'search by id', ->
      Account.search(id.toString()).then (account) ->
        account.username.should.be.equal username

    it 'search by email', ->
      Account.search(email).then (account) ->
        account.username.should.be.equal username

    it 'search by username', ->
      Account.search(username).then (account) ->
        account._id.toString().should.be.equal id.toString()

    it 'search undefined account', ->
      Account.search(randomAccount().username).then (account) ->
        expect(account).to.not.exists

  describe '::createToken', ->
    it 'should success', ->
      createAccount().then (account) ->
        account.createToken('full_access').then ({code}) ->
          Account.findOne('tokens.code': code).then (account) ->
            _.findWhere(account.tokens,
              code: code
            ).type.should.be.equal 'full_access'
