{pluggable, config} = app

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
    exports.render 'widget', req,
      transfer_remainder: account.billing.balance / config.plugins.shadowsocks.price_bucket / (1000 * 1000 * 1000 / config.plugins.shadowsocks.billing_bucket)
      traffic_24hours: null
      traffic_7days: null
      traffic_30days: null
    , callback

exports.registerServiceHook 'enable',
  filter: (req, callback) ->

exports.registerServiceHook 'disable',
  filter: (req, callback) ->

app.express.use '/plugin/shadowsocks', require './router'
