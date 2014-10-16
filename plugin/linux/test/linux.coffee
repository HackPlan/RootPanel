console.log '1'

application.run ->
  console.log '2'
  linux = require '../linux'

  describe 'linux', ->
    console.log '3'
    describe 'getPasswdMap', ->
      it 'should an object', (done) ->
        linux.getPasswdMap (passwd_map) ->
          console.log passwd_map
          passwd_map.should.an 'object'
          done()
