fs = require 'fs'

getPasswdMap = (callback) ->
  fs.readFile '/etc/passwd', (err, content) ->
    result = {}

    for line in _.compact(content.toString().split '\n')
      [username, password, uid] = line.split ':'
      result[uid] = username

    callback result

describe 'interface/Node', ->
  clusters = null

  master = null
  slave = null

  before ->
    {clusters, config} = app

    config.nodes =
      master:
        host: 'localhost'
        master: true

      slave:
        host: '127.0.0.1'

    try
      fs.unlinkSync '/tmp/test_file'
      fs.unlinkSync '/tmp/test_file_remote'
    catch err

  it 'initNodes', ->
    clusters.initNodes()
    {master, slave} = clusters.nodes

  it 'runCommand', (done) ->
    master.runCommand 'echo "hello world"', (err, stdout, stderr) ->
      expect(err).to.not.exist
      stdout.should.be.equal 'hello world\n'
      stderr.should.be.equal ''
      done err

  it 'runCommandRemote', (done) ->
    slave.runCommand 'echo "hello world"', (err, stdout, stderr) ->
      expect(err).to.not.exist
      stdout.should.be.equal 'hello world\n'
      stderr.should.be.equal ''
      done err

  it 'exec'

  it 'execRemote'

  it 'writeFile', (done) ->
    master.writeFile '/tmp/test_file', 'Test',
      owner: 'rpadmin'
      mode: '700'
    , (err) ->
      done err if err

      fs.stat '/tmp/test_file', (err, stat) ->
        getPasswdMap (passwd_map) ->
          parseInt(stat.mode.toString(8), 10).should.be.equal 100700
          passwd_map[stat.uid].should.be.equal 'rpadmin'
          done err

  it 'writeFileRemote', (done) ->
    slave.writeFile '/tmp/test_file_remote', 'Remote',
      owner: 'rpadmin'
      mode: '700'
    , (err) ->
      done err if err

      fs.stat '/tmp/test_file_remote', (err, stat) ->
        getPasswdMap (passwd_map) ->
          parseInt(stat.mode.toString(8), 10).should.be.equal 100700
          passwd_map[stat.uid].should.be.equal 'rpadmin'
          done err

  it 'readFile', (done) ->
    master.readFile '/tmp/test_file', (err, body) ->
      body.should.be.equal 'Test'
      done err

  it 'readFileRemote', (done) ->
    slave.readFile '/tmp/test_file_remote', (err, body) ->
      body.should.be.equal 'Remote'
      done err
