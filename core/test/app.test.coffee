describe 'app', ->
  it 'should can startup', ->
    @timeout 20000
    require('../../app').start()

  it 'should connected to mongodb', (done) ->
    async.forever (callback) ->
      if app.db.readyState == 1
        callback true
      else
        setImmediate callback
    , ->
      done()

  it 'app.libs should be loaded', ->
    {_, express, fs, mongoose} = app.libs
    _.should.be.ok
    express.should.be.ok
    fs.should.be.ok
    mongoose.should.be.ok

  it 'app.logger should be available', ->
    app.logger.info.should.be.a 'function'
    app.logger.error.should.be.a 'function'

  it 'config.coffee should exists', ->
    fs.existsSync("#{__dirname}/../../config.coffee").should.be.ok

  it 'session.key should exists', ->
    fs.existsSync("#{__dirname}/../../session.key").should.be.ok

  it 'models should be available', ->
    {Account, Ticket} = app.models
    Account.find.should.be.a 'function'
    Ticket.find.should.be.a 'function'
