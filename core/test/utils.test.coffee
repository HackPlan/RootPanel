describe 'utils', ->
  utils = require '../utils'

  describe 'rx', ->
    it 'username', ->
      utils.rx.username.test('jysperm').should.be.ok
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

  it 'sha256'

  it 'md5'

  it 'randomSalt'

  it 'randomString'

  it 'hashPassword'

  it 'wrapAsync'
