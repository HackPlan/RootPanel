{createAccount} = helpers

describe 'model.security-log', ->
  {SecurityLog, Account: {Token}} = root

  describe '.createLog', ->
    it 'should success', ->
      createAccount().then (account) ->
        account.createToken('full_access').then (token) ->
          SecurityLog.createLog(account,
            token: token
            type: 'login'
          ).then (log) ->
            log.token.code.should.be.exists
            expect(log.token.updated_at).to.not.exists
