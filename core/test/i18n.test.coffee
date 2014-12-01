describe 'i18n', ->
  i18n = null

  before ->
    {i18n} = app

    i18n.i18n_data['zh_CN'] ?= {}
    i18n.i18n_data['en'] ?= {}

    i18n.i18n_data['zh_CN']['test'] =
      test: '测试'
      title: '工单 __id__'
      account:
        username: '用户名'

    i18n.i18n_data['en']['test'] =
      test: 'Test'

  it 'parseLanguageCode', ->
    i18n.parseLanguageCode('zh_CN').should.be.eql
      language: 'zh_CN'
      lang_country: 'zh_CN'
      lang: 'zh'
      country: 'CN'

    i18n.parseLanguageCode('en').should.be.eql
      language: 'en'
      lang_country: 'en'
      lang: 'en'
      country: null

    i18n.parseLanguageCode('en-us').should.be.eql
      language: 'en-us'
      lang_country: 'en_US'
      lang: 'en'
      country: 'US'

  it 'getLanguagesByReq', ->
    i18n.getLanguagesByReq(
      headers: {}
      cookies: {}
    ).should.be.eql ['*']

    i18n.getLanguagesByReq(
      headers:
        'accept-language': 'zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4'
      cookies:
        language: 'zh'
    ).should.be.eql ['zh', 'zh-CN', 'en', 'zh-TW']

    i18n.getLanguagesByReq(
      headers:
        'accept-language': 'en;q=0.8,zh;q=0.6,zh-TW;q=0.4'
      cookies: {}
    ).should.be.eql ['en', 'zh', 'zh-TW']

  it 'translateByLanguage', ->
    i18n.translateByLanguage('test.test', 'zh_CN').should.equal '测试'
    i18n.translateByLanguage('test.test', 'en').should.equal 'Test'
    i18n.translateByLanguage('test.account.username', 'zh_CN').should.equal '用户名'

  it 'translate', ->
    i18n.translate(
      'test.account.username', ['en', 'zh_CN']
    ).should.be.equal '用户名'

    i18n.translate(
      'test.test', ['en', 'zh_CN']
    ).should.be.equal 'Test'

    i18n.translate(
      'test.account.username', ['en']
    ).should.be.equal 'test.account.username'

  it 'getTranslator', ->
    translator = i18n.getTranslator ['en', 'zh_CN']

    translator('test.account.username').should.be.equal '用户名'
    translator('test.test').should.be.equal 'Test'
    translator('test.title', {id: 5}).should.be.equal '工单 5'

  it 'languagePriority', ->
    i18n.languagePriority(['*']).should.be.eql ['zh_CN', 'en']
    i18n.languagePriority(['en', 'zh-TW', 'zh', 'zh-CN']).should.be.eql ['en', 'zh_CN']
    i18n.languagePriority(['en', 'zh', 'zh-TW']).should.be.eql ['en', 'zh_CN']

  it 'getTranslatorByReq', ->
    translator = i18n.getTranslatorByReq(
      headers: {}
      cookies: {}
    )

    translator('test.account.username').should.be.equal '用户名'
    translator('test.test').should.be.equal '测试'

    translator = i18n.getTranslatorByReq(
      headers:
        'accept-language': 'en;q=0.8,zh;q=0.6,zh-TW;q=0.4'
      cookies: {}
    )

    translator('test.account.username').should.be.equal '用户名'
    translator('test.test').should.be.equal 'Test'

  it 'pickClientLocale'

  it 'localeHash'
