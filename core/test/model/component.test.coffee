describe 'model.component', ->
  Component = require '../../model/component'

  describe '.createComponent', ->
    it 'should success', ->
      createAccount().then (account) ->
        Component.createComponent account,
          name: 'linux component'
          type: 'linux'
          node: 'master'
        .then ->
          Component.getComponents(account).then (components) ->
            _.findWhere(components,
              name: 'linux component'
            ).should.be.exists

  describe '::hasMember', ->
    it 'should success', ->
      createAccount().then (account) ->
        createComponent({account}).then (component) ->
          component.hasMember(account).should.be.true

  describe '::populate', ->
    it 'should success', ->
      createComponent().then (component) ->
        component.populate().then ->
          component.account.username.should.be.exists

createComponent = (options) ->
  options = _.defaults {}, options,
    name: 'linux component'
    type: 'linux'
    node: 'master'

  Q().then ->
    if options.account
      return options.account
    else
      return createAccount()
  .then (account) ->
    root.Component.createComponent account, options
