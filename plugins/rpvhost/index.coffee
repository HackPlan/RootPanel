module.exports = class RPVHost
  constructor: (@injector, {@green_style, @index_page}) ->
    @injector.paymentProvider 'taobao', new TaobaoPayment()

    @injector.view 'layout',
      filename: __dirname + '/view/layout'
      locals: rpvhost: @

    @injector.view 'panel/financials',
      filename: __dirname + '/view/taobao'
      locals: rpvhost: @

    if @index_page
      @injector.router('/').get '/', (req, res) ->
        res.render __dirname + '/view/index'

class TaobaoPayment
  populateFinancials: (req, financial) ->
    callback plugin.getTranslator(req) 'view.payment_details',
      order_id: deposit_log.payload.order_id
