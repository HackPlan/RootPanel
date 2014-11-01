describe 'cache', ->
  cache = null
  redis = null

  before ->
    {cache, redis} = app

  describe 'hashKey', ->
    it 'should success', ->
      cache.hashKey('cache_key').should.be.equal 'RP:cache_key'
      cache.hashKey({param: 'value'}).should.equal 'RP:{"param":"value"}'
      cache.hashKey({a: 'b', c: 'd', e: 2}).should.equal 'RP:{"a":"b","c":"d","e":2}'
      cache.hashKey({e: 2, a: 'b', c: 'd'}).should.equal 'RP:{"a":"b","c":"d","e":2}'

  describe 'try', ->
    it 'should success when cache not exist', (done) ->
      cache.try 'test_key', (SET, key) ->
        key.should.be.equal 'test_key'
        SET 'test_key_value'
      , (value) ->
        value.should.be.equal 'test_key_value'

        redis.get 'RP:test_key', (err, value) ->
          value.should.be.equal 'test_key_value'

          done()

    it 'should success when cache exist', (done) ->
      cache.try 'test_key', ->
        throw new Error 'should not be called'
      , (value) ->
        value.should.be.equal 'test_key_value'
        done()

    it 'should success with param', (done) ->
      cache.try
        key: 'test2'
        object_id: 10
      , (SET, key) ->
        key.object_id.should.be.equal 10
        SET 100
      , (value) ->
        value.should.be.equal 100
        done()

    it 'should success with JSON and SETEX', (done) ->
      cache.try 'test_key3', (SETEX) ->
        SETEX
          value_of: 'test_key3'
        , 60

      , (value) ->
        value.value_of.should.be.equal 'test_key3'

        redis.ttl 'RP:test_key3', (err, seconds) ->
          seconds.should.above 0
          cache.delete 'test_key3', done

  describe 'delete', ->
    it 'should success', (done) ->
      cache.delete 'test_key', ->
        redis.get 'RP:test_key', (err, value) ->
          expect(value).to.not.exist
          done()

    it 'should success with param', (done) ->
      cache.delete
        key: 'test2'
        object_id: 10
      , ->
        redis.get
          key: 'test2'
          object_id: 10
        , (err, value) ->
          expect(value).to.not.exist
          done()
