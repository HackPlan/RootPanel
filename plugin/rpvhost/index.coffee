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
  body: '官方博客'

exports.registerHook 'billing.payment_methods',
  widget_generator: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/payment_method.jade'),
      account: account
      config: config
    , (err, html) ->
      callback html

exports.registerHook 'view.pay.display_payment_details',
  type: 'taobao'
  filter: (account, deposit_log, callback) ->
    callback account.t 'plugins.rpvhost.view.payment_details',
      order_id: deposit_log.payload.order_id

app.get '/', renderAccount, (req, res) ->
  res.render path.join(__dirname, './view/index')
