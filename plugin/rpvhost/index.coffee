path = require 'path'
jade = require 'jade'

{pluggable, config} = app
{renderAccount} = app.middleware

module.exports = pluggable.createHelpers exports =
  name: 'rpvhost'
  type: 'extension'

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

app.get '/', renderAccount, (req, res) ->
  exports.render 'index', req, {}, (html) ->
    res.send html
