module.exports = class ShadowsocksComponent
  @generatePort: ->
    port = 10000 + Math.floor Math.random() * 40000

    Component.findOne
      type: 'shadowsocks.shadowsocks'
      'options.port': port
    .then (component) ->
      if component
        return ShadowsocksComponent.generatePort()
      else
        return port

  initialize: (component) ->

  update: (component) ->

  destroy: (component) ->

  actions: [
    resetPassword:
      handler: ->

    setCipher:
      handler: ->
  ]
