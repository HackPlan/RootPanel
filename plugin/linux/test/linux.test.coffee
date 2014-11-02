describe 'plugin/linux', ->
  linux = null
  agent = null
  cache = null
  redis = null

  before ->
    linux = require '../linux'
    {cache, redis} = app
    {agent} = namespace.accountRouter

  describe 'router', ->
    it 'GET monitor', (done) ->
      agent.get '/public/monitor'
      .expect 200
      .end done

  describe 'createUser', ->
    it 'pending'

  describe 'deleteUser', ->
    it 'pending'

  describe 'setResourceLimit', ->
    it 'pending'

  describe 'getPasswdMap', ->
    it 'pending'

  describe 'getMemoryInfo', ->
    it 'pending'

  describe 'getProcessList', ->
    it 'pending'

  describe 'getStorageQuota', ->
    it 'pending'

  describe 'getSystemInfo', ->
    before (done) ->
      cache.delete 'linux.getSystemInfo', done

    it 'should success', (done) ->
      linux.getSystemInfo (system) ->
        system.system.should.match /Ubuntu/
        system.hostname.should.be.a 'string'
        system.cpu.should.be.a 'string'
        system.uptime.should.be.a 'number'
        system.loadavg.length.should.be.equal 3
        system.time.should.be.exist

        for address in system.address
          expect(
            address.match(/\d+\.\d+\.\d+\.\d+/) or
            address.match(/::/)
          ).to.be.ok

        redis.get 'RP:linux.getSystemInfo', (err, system) ->
          system.should.be.exist
          done()

  describe 'getStorageInfo', ->
    it 'pending'

  describe 'getResourceUsageByAccounts', ->
    it 'pending'

  describe 'getResourceUsageByAccount', ->
    it 'pending'
