describe 'plugin/linux', ->
  linux = null
  cache = null
  redis = null
  utils = null

  agent = null
  username = null

  before ->
    linux = require '../linux'
    {cache, redis, utils} = app
    {agent} = namespace.accountRouter

    username = "linux_test#{utils.randomString(20)}"

  describe 'router', ->
    it 'GET monitor', (done) ->
      agent.get '/public/monitor'
      .expect 200
      .end done

  describe 'createUser', ->
    it 'should success', (done) ->
      linux.createUser {username: username}, ->
        fs.existsSync("/home/#{username}").should.be.ok
        done()

  describe 'setResourceLimit', ->
    it 'should success', (done) ->
      account =
        username: username
        billing:
          services: ['linux']
        resources_limit:
          storage: 300

      linux.setResourceLimit account, ->
        done()

  describe 'deleteUser', ->
    it 'should success', (done) ->
      linux.deleteUser {username: username}, ->
        expect(fs.existsSync("/home/#{username}")).to.not.ok
        done()

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
    before (done) ->
      cache.delete 'linux.getStorageQuota', done

    it 'should success', (done) ->
      linux.getStorageQuota (storage_quota) ->
        for k, v of storage_quota
          v.username.should.be.equal k
          v.size_used.should.be.a 'number'
          v.inode_used.should.be.a 'number'

        done()

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
            address.match(/:.*:/)
          ).to.be.ok

        redis.get 'RP:linux.getSystemInfo', (err, system) ->
          system.should.be.exist
          done()

  describe 'getStorageInfo', ->
    before (done) ->
      cache.delete 'linux.getStorageInfo', done

    it 'should success', (done) ->
      linux.getStorageInfo (storage_info) ->
        storage_info.used.should.be.a 'number'
        storage_info.free.should.be.a 'number'
        storage_info.total.should.be.a 'number'
        storage_info.used_per.should.be.a 'number'
        storage_info.free_per.should.be.a 'number'
        done()

  describe 'getResourceUsageByAccounts', ->
    before (done) ->
      cache.delete 'linux.getResourceUsageByAccounts', done

    it 'should success', (done) ->
      linux.getResourceUsageByAccounts (resource_usage) ->
        for item in resource_usage
          item.username.should.be.a 'string'
          item.cpu.should.be.a 'number'
          item.memory.should.be.a 'number'
          item.storage.should.be.a 'number'
          item.process.should.be.a 'number'

        done()

  describe 'getResourceUsageByAccount', ->
    it 'pending'
