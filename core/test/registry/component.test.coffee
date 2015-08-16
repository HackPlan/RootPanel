{createAccount} = helpers
{Component} = root

describe 'registry.component', ->
  describe 'ComponentProvider', ->
    describe 'create and destroyComponent', ->
      initializeCount = 0
      destroyCount = 0

      before ->
        root.components.register 'mock',
          plugin: root.plugins.byName 'built-in'

          initialize: (component) ->
            initializeCount++

          destroy: (component) ->
            destroyCount++

      it 'should success', ->
        provider = root.components.byName 'built-in.mock'

        createAccount().then (account) ->
          provider.create account, root.servers.master(),
            name: 'test'
          .then (component) ->
            initializeCount.should.be.equal 1
            component.type.should.be.equal 'built-in.mock'

            provider.destroyComponent(component).then ->
              destroyCount.should.be.equal 1
              Component.findById(component._id).then (component) ->
                expect(component).to.not.exists
