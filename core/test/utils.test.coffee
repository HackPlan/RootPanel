utils = require '../utils'

describe 'utils', ->
  describe 'rx', ->
    it 'username', ->
      utils.rx.username.test('jysperm').should.be.ok
      utils.rx.username.test('JYSPERM').should.not.be.ok
      utils.rx.username.test('s').should.not.be.ok
      utils.rx.username.test('root-panel').should.not.be.ok
      utils.rx.username.test('184300584').should.not.be.ok
      utils.rx.username.test('jysperm@gmail.com').should.not.be.ok

    it 'email', ->
      utils.rx.email.test('jysperm@gmail.com').should.be.ok
      utils.rx.email.test('').should.not.be.ok
      utils.rx.email.test('jysperm').should.not.be.ok
      utils.rx.email.test('jysperm@').should.not.be.ok
      utils.rx.email.test('@gmail.com').should.not.be.ok

    it 'password', ->
      utils.rx.password.test('passwd').should.be.ok
      utils.rx.password.test('').should.not.be.ok

    it 'domain', ->
      utils.rx.domain.test('jysperm.me').should.be.ok
      utils.rx.domain.test('*.jysperm.me').should.be.ok
      utils.rx.domain.test('www.jysperm.me').should.be.ok
      utils.rx.domain.test('0-ms.org').should.be.ok
      utils.rx.domain.test('localhost').should.be.ok
      utils.rx.domain.test('.jysperm.me').should.not.be.ok
      utils.rx.domain.test('-jysperm').should.not.be.ok
      utils.rx.domain.test('jy sperm').should.not.be.ok
      utils.rx.domain.test('jysperm.').should.not.be.ok

    it 'filename', ->
      utils.rx.filename.test('filename').should.be.ok
      utils.rx.filename.test('').should.not.be.ok
      utils.rx.filename.test('"filename').should.not.be.ok
      utils.rx.filename.test('file\name').should.not.be.ok

    it 'url', ->
      utils.rx.url.test('http://jysperm.me').should.be.ok
      utils.rx.url.test('https://jysperm.me/about').should.be.ok
      utils.rx.url.test('ssh://jysperm.me').should.not.be.ok

  it 'sha256', ->
    expect(utils.sha256()).to.be.not.exist
    sha256 = '0554af0347e02ce032a1c6a292ed7e704c734ce338e71b39e21a73fa9b4d8fea'
    utils.sha256('jysperm').should.be.equal sha256

  it 'md5', ->
    expect(utils.md5()).to.be.not.exist
    utils.md5('jysperm').should.be.equal 'ff42fce67bcd7dd060293d3cb42638ba'

  it 'randomSalt', ->
    random1 = utils.randomSalt()
    random2 = utils.randomSalt()

    random1.should.have.length 64
    random1.should.be.not.equal random2

  it 'randomString', ->
    random1 = utils.randomString 10
    random2 = utils.randomString 10
    random3 = utils.randomString 20

    random1.should.have.length 10
    random1.should.be.not.equal random2
    random3.should.have.length 20

  it 'hashPassword', ->
    sha256 = '016899230b83a136fea361680e3a0c687440cd866ae67448fa72b007b04269dc'
    utils.hashPassword('passwd', 'salt').should.be.equal sha256

  describe 'wrapAsync', ->
    it 'should work with basic usage', (done) ->
      func = (callback) ->
        callback 'result'

      utils.wrapAsync(func) (err, result) ->
        expect(err).to.be.not.exist
        result.should.be.equal 'result'

        done()

    it 'should work with async', (done) ->
      func = (callback) ->
        callback 'result'

      async.parallel [
        utils.wrapAsync func
        utils.wrapAsync func
      ], (err, result) ->
        expect(err).to.be.not.exist
        result[0].should.be.equal 'result'
        result[1].should.be.equal 'result'

        done()

  describe 'pickErrorName', ->
    it 'should work with two errors', ->
      error =
        errors:
          email:
            message: 'invalid_email'

          username:
            message: 'invalid_username'

      expect(utils.pickErrorName(error) in [
        'invalid_email', 'invalid_username'
      ]).to.be.ok

    it 'should work with no error', ->
      expect(utils.pickErrorName({})).to.be.null
      expect(utils.pickErrorName({errors: {}})).to.be.null
