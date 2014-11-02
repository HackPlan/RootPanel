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
    before (done) ->
      cache.delete 'linux.getPasswdMap', done

    it 'should success', (done) ->
      linux.getPasswdMap (passwd_map) ->
        passwd_map.should.be.a 'object'

        for k, v of passwd_map
          parseInt(k).toString().should.be.equal k
          v.should.be.a 'string'

        done()

  describe 'getMemoryInfo', ->
    before (done) ->
      cache.delete 'linux.getMemoryInfo', done

    it 'should success', (done) ->
      linux.getMemoryInfo (memory_info) ->
        for field in [
          'used', 'cached', 'buffers', 'free', 'total', 'swap_used', 'swap_free'
          'swap_total', 'used_per', 'cached_per', 'buffers_per', 'free_per'
          'swap_used_per', 'swap_free_per'
        ]
          expect(isNaN(memory_info[field])).to.be.false
          memory_info[field].should.be.a 'number'

        done()

  describe 'getProcessList', ->
    before (done) ->
      cache.delete 'linux.getProcessList', done

    it 'should success', (done) ->
      linux.getProcessList (plist) ->
        plist.should.be.a 'array'

        for p in plist
          p.user.should.be.a 'string'
          p.time.should.be.a 'number'
          p.pid.should.be.a 'number'
          p.cpu_per.should.be.a 'number'
          p.mem_per.should.be.a 'number'
          p.vsz.should.be.a 'number'
          p.rss.should.be.a 'number'
          p.tty.should.be.a 'string'
          p.stat.should.be.a 'string'
          p.start.should.be.a 'string'
          p.command.should.be.a 'string'

        done()

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
