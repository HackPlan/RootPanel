plugin = app.extends.plugin.register
  name: 'rpvhost'

  initialize: ->
    unless @config.index_page == false
      app.express.get '/', (req, res) =>
        @render 'index', req, {}, (err, html) ->
          res.send html

if plugin.config.green_style
  plugin.registerHook 'view.layout.styles',
    path: '/plugin/rpvhost/style/green.css'

plugin.registerHook 'view.layout.menu_bar',
  href: 'http://blog.rpvhost.net'
  target: '_blank'
  t_body: 'official_blog'

plugin.registerHook 'billing.payment_methods',
  type: 'taobao'

  widgetGenerator: (req, callback) ->
    plugin.render 'payment_method', req, {}, callback

  detailsMessage: (req, deposit_log, callback) ->
    callback plugin.getTranslator(req) 'view.payment_details',
      order_id: deposit_log.payload.order_id
