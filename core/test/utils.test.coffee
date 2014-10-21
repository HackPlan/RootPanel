describe 'utils', ->
  utils = require '../utils'

  describe 'rx', ->
    it 'username', ->
      utils.rx.username.test('jysperm').should.be.ok
      utils.rx.username.test('s').should.not.be.ok
      utils.rx.username.test('root-panel').should.not.be.ok
      utils.rx.username.test('184300584').should.not.be.ok
      utils.rx.username.test('jysperm@gmail.com').should.not.be.ok

    it 'email'

    it 'password'

    it 'domain'

    it 'filename'

    it 'url'

  it 'sha256'

  it 'md5'

  it 'randomSalt'

  it 'randomString'

  it 'hashPassword'

  it 'wrapAsync'
