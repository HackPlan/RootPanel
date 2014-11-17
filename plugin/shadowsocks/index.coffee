{_, fs} = app.libs
{pluggable, config, utils} = app
{Financials} = app.models

exports = module.exports = class ShadowSocksPlugin extends pluggable.Plugin
  @NAME: 'shadowsocks'
  @type: 'service'
  @dependencies: ['supervisor', 'linux']

shadowsocks = require './shadowsocks'

exports.registerHook 'plugin.wiki.pages',
  always_notice: true
  t_category: 'plugins.shadowsocks.'
  t_title: 'README.md'
  language: 'zh_CN'
  content_markdown: fs.readFileSync("#{__dirname}/wiki/README.md").toString()

exports.registerHook 'view.panel.scripts',
  path: '/plugin/shadowsocks/script/panel.js'

exports.registerHook 'view.panel.styles',
  path: '/plugin/shadowsocks/style/panel.css'

exports.registerHook 'view.panel.widgets',
  generator: (req, callback) ->
    price_gb = config.plugins.shadowsocks.price_bucket * (1000 * 1000 * 1000 / config.plugins.shadowsocks.billing_bucket)

    shadowsocks.accountUsage req.account, (result) ->
      _.extend result,
        transfer_remainder: req.account.billing.balance / price_gb

      exports.render 'widget', req, result, callback

exports.registerHook 'view.admin.sidebars',
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

exports.registerHook 'app.started',
  action: ->
    shadowsocks.initSupervisor ->

exports.registerServiceHook 'enable',
  filter: (req, callback) ->
    shadowsocks.initAccount req.account, callback

exports.registerServiceHook 'disable',
  filter: (req, callback) ->
    shadowsocks.deleteAccount req.account, callback

app.express.use '/plugin/shadowsocks', require './router'

setInterval shadowsocks.monitoring, config.plugins.shadowsocks.monitor_cycle
