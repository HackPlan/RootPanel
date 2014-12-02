{_, fs} = app.libs
{pluggable, config, utils} = app
{Financials} = app.models

shadowsocks = require './shadowsocks'

shadowsocksPlugin = module.exports = new Plugin
  name: 'shadowsocks'
  dependencies: ['supervisor', 'linux']

  register_hooks:
    'plugin.wiki.pages':
      t_category: 'plugins.shadowsocks.'
      t_title: 'README.md'
      language: 'zh_CN'
      content_markdown: fs.readFileSync("#{__dirname}/wiki/README.md").toString()

    'app.started': [
      action: shadowsocks.initSupervisor
    ,
      register_if: -> @config.monitor_cycle
      action: ->
        setInterval shadowsocks.monitoring, config.plugins.shadowsocks.monitor_cycle
    ]

    'view.admin.sidebars':
      generator: (req, callback) ->
        Financials.find
          type: 'usage_billing'
          'payload.service': 'shadowsocks'
          created_at:
            $gte: new Date Date.now() - 30 * 24 * 3600 * 1000
        , (err, financials) ->
          time_range =
            traffic_24hours: 24 * 3600 * 1000
            traffic_3days: 3 * 24 * 3600 * 1000
            traffic_7days: 7 * 24 * 3600 * 1000
            traffic_30days: 30 * 24 * 3600 * 1000

          traffic_result = {}

          for name, range of time_range
            logs = _.filter financials, (i) ->
              return i.created_at.getTime() > Date.now() - range

            traffic_result[name] = _.reduce logs, (memo, i) ->
              return memo + i.payload.traffic_mb
            , 0

          exports.render 'admin/sidebar', req, traffic_result, callback

  initialize: ->
    app.express.use '/plugin/shadowsocks', require './router'

shadowsocksPlugin.registerComponent
  name: 'shadowsocks'

  initialize: shadowsocks.initAccount
  destroy: shadowsocks.deleteAccount

  register_hooks:
    'view.panel.scripts':
      path: '/plugin/shadowsocks/script/panel.js'

    'view.panel.styles':
      path: '/plugin/shadowsocks/style/panel.css'

    'view.panel.widgets':
      generator: (req, callback) ->
        bucket_of_gb = 1000 * 1000 * 1000 / config.plugins.shadowsocks.billing_bucket
        price_gb = config.plugins.shadowsocks.price_bucket * bucket_of_gb

        shadowsocks.accountUsage req.account, (result) ->
          _.extend result,
            transfer_remainder: req.account.billing.balance / price_gb

          exports.render 'widget', req, result, callback
