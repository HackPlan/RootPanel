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
      type: 'taobao'
      widget_generator: (req, callback) ->
        rpvhostPlugin.render 'payment_method', req, {}, callback

      details_message: (req, deposit_log, callback) ->
        callback rpvhostPlugin.getTranslator(req) 'view.payment_details',
          order_id: deposit_log.payload.order_id

    'view.layout.styles':
      register_if: -> @config.green_style
      path: '/plugin/rpvhost/style/green.css'

  initialize: ->
    unless @config.index_page == false
      app.express.get '/', (req, res) =>
        @render 'index', req, {}, (html) ->
          res.send html
