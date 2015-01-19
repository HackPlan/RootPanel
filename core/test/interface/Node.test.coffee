describe.skip 'interface/Node', ->
  {Node, master, slave} = {}

  before ->
    {config} = app
    {Node} = app.interfaces

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
    {master, slave} = Node.initNodes()

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
        parseInt(stat.mode.toString(8), 10).should.be.equal 100700
        stat.uid.should.be.equal process.getuid()
        done err

  it 'writeFileRemote', (done) ->
    @timeout 5000

    slave.writeFile '/tmp/test_file_remote', 'Remote',
      owner: 'rpadmin'
      mode: '700'
    , (err) ->
      done err if err

      fs.stat '/tmp/test_file_remote', (err, stat) ->
        parseInt(stat.mode.toString(8), 10).should.be.equal 100700
        stat.uid.should.be.equal process.getuid()
        done err

  it 'readFile', (done) ->
    master.readFile '/tmp/test_file', (err, body) ->
      body.should.be.equal 'Test'
      done err

  it 'readFileRemote', (done) ->
    slave.readFile '/tmp/test_file_remote', (err, body) ->
      body.should.be.equal 'Remote'
      done err
