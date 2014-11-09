{pluggable, config, utils} = app
{Financials} = app.models

exports = module.exports = class ShadowSocksPlugin extends pluggable.Plugin
  @NAME: 'shadowsocks'
  @type: 'service'
  @dependencies: ['supervisor', 'linux']

shadowsocks = require './shadowsocks'

exports.registerHook 'plugin.wiki.pages',
  t_category: 'shadowsocks'
  t_title: 'README.md'
  language: 'zh_CN'
  content_markdown: fs.readFileSync("#{__dirname}/wiki/README.md").toString()

exports.registerHook 'view.panel.scripts',
  path: '/plugin/shadowsocks/script/panel.js'

exports.registerHook 'view.panel.styles',
  path: '/plugin/shadowsocks/style/panel.css'

if config.plugins.shadowsocks.green_style
  exports.registerHook 'view.layout.styles',
    path: '/plugin/shadowsocks/style/layout.css'

exports.registerHook 'view.panel.widgets',
  generator: (req, callback) ->
    Financials.find
      account_id: account._id
      type: 'usage_billing'
      'payload.service': 'shadowsocks'
    , (err, financials) ->
      time_range =
        traffic_24hours: 24 * 3600 * 1000
        traffic_7days: 7 * 24 * 3600 * 1000
        traffic_30days: 30 * 24 * 3600 * 1000

      result = {}

      for name, range of time_range
        logs = _.filter financials, (i) ->
          return i.created_at.getTime() > Date.now() - range

        result[name] = _.reduce logs, (memo, i) ->
          return memo + i.payload.traffic_mb
        , 0

      _.extend result,
        transfer_remainder: account.billing.balance / config.plugins.shadowsocks.price_bucket / (1000 * 1000 * 1000 / config.plugins.shadowsocks.billing_bucket)

      exports.render 'widget', req, result, callback

exports.registerServiceHook 'enable',
  filter: (req, callback) ->
    shadowsocks.initAccount req.account, callback

exports.registerServiceHook 'disable',
  filter: (req, callback) ->
    shadowsocks.deleteAccount req.account, callback

app.express.use '/plugin/shadowsocks', require './router'

setInterval shadowsocks.monitoring, config.plugins.shadowsocks.monitor_cycle
