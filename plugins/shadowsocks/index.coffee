module.exports = class Shadowsocks
  constructor: (@injector) ->
    @injector.component 'shadowsocks', new ShadowsocksComponent()

    @injector.widget 'panel',
      repeating:
        components:
          shadowsocks: every: true
      generator: (account, component) ->
        root.views.render __dirname + '/view/widget'

    setInterval =>
      @getManager().monitoring().then (usages) =>
        Q.all usages.map ({port, bytes}) =>
          root.billing.usagesBilling @getAccountByPort(port), 'traffic', bytes

    , 5 * 60 * 1000

  getManager: (node) ->
    if node
      return new ShadowsocksManager root.servers.byName node
    else
      return new ShadowsocksManager root.servers.master()

  getAccountByPort: (port) ->
    Component.findOne
      type: 'shadowsocks.shadowsocks'
      'options.port': port
    .then ({account_id}) ->
      Account.findById account_id
