module.exports = class Builtin extends root.Plugin
  activate: ->
    @injector.couponType 'cash', new CashCoupon()

    @injector.router('/').get '/', (req, res) ->
      res.redirect '/panel/'

class CashCoupon
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
