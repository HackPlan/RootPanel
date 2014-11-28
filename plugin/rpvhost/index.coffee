{jade, path, fs} = app.libs
{pluggable, config} = app
{Plugin} = app.classes

rpvhostPlugin = module.exports = new Plugin
  name: 'rpvhost'

  register_hooks:
    'view.layout.menu_bar':
      href: 'http://blog.rpvhost.net'
      target: '_blank'
      t_body: 'official_blog'

    'billing.payment_methods':
      widget_generator: (req, callback) ->
        exports.render 'payment_method', req, {}, callback

    'view.pay.display_payment_details.taobao':
      filter: (req, deposit_log, callback) ->
        callback rpvhostPlugin.t(req) 'view.payment_details',
          order_id: deposit_log.payload.order_id

    'view.layout.styles':
      test: -> @config.green_style
      path: '/plugin/rpvhost/style/green.css'

  initialize: ->
    unless @config.index_page == false
      app.express.get '/', (req, res) ->
        rpvhostPlugin.render 'index', req, {}, (html) ->
          res.send html
