{Account, CouponCode} = root

module.exports = class Builtin extends root.Plugin
  activate: ->
    @injector.couponType 'cash', cashCoupon

    @injector.paymentProvider 'manual', manualPayment

    @injector.router('/').get '/', (req, res) ->
      res.redirect '/panel/'

    @injector.hook 'account.after_register',
      action: (account) ->
        Account.count().then (count) ->
          if count == 1
            account.joinGroup 'root'

    @injector.component 'sample', sampleComponent

cashCoupon =
  validate: (account, coupon) ->
    apply_log = _.find coupon.apply_log, (log) ->
      return log.account_id.equals account._id

    if apply_log
      return false

    CouponCode.findOne
      type: 'cash'
      'options.category': coupon.options.category
      'apply_log.account_id': account._id
    .then (coupon) ->
      if coupon
        return false
      else
        return true

  apply: (account, coupon) ->
    account.incBalance coupon.options.amount, 'deposit',
      type: 'coupon'
      order_id: coupon.code

  populateCoupon: (coupon) ->
    return coupon

sampleComponent =
  initialize: (component) ->

  destroy: (component) ->

manualPayment =
  populateFinancial: (req, financial) ->
