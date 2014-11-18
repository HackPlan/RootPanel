{jade, path, fs} = app.libs
{pluggable, config} = app

exports = module.exports = class RPVhostPlugin extends pluggable.Plugin
  @NAME: 'rpvhost'
  @type: 'extension'

exports.registerHook 'plugin.wiki.pages',
  t_category: 'plugins.rpvhost.'
  t_title: 'Terms.md'
  language: 'zh_CN'
  content_markdown: fs.readFileSync("#{__dirname}/wiki/Terms.md").toString()

exports.registerHook 'view.layout.menu_bar',
  href: '//blog.rpvhost.net'
  target: '_blank'
  t_body: 'plugins.rpvhost.official_blog'

exports.registerHook 'billing.payment_methods',
  widget_generator: (req, callback) ->
    exports.render 'payment_method', req, {}, callback

exports.registerHook 'view.pay.display_payment_details',
  type: 'taobao'
  filter: (req, deposit_log, callback) ->
    callback exports.t(req) 'view.payment_details',
      order_id: deposit_log.payload.order_id

if config.plugins.rpvhost.green_style
  exports.registerHook 'view.layout.styles',
    path: '/plugin/rpvhost/style/green.css'

unless config.plugins.rpvhost.index_page == false
  app.express.get '/', (req, res) ->
    exports.render 'index', req, {}, (html) ->
      res.send html
