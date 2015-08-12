{createAccount} = helpers

describe 'registry.component', ->
  {Component} = root

  describe 'ComponentProvider', ->
    describe 'create and destroyComponent', ->
      initializeCount = 0
      destroyCount = 0

      before ->
        root.components.register 'mock',
          plugin:
            name: 'mock'

          initialize: (component) ->
            initializeCount++

          destroy: (component) ->
            destroyCount++

      it 'should success', ->
        provider = root.components.byName 'mock.mock'

        createAccount().then (account) ->
          provider.create account, root.servers.master(),
            name: 'test'
          .then (component) ->
            initializeCount.should.be.equal 1
            component.type.should.be.equal 'mock.mock'

            provider.destroyComponent(component).then ->
              destroyCount.should.be.equal 1
              Component.findById(component._id).then (component) ->
                expect(component).to.not.exists
