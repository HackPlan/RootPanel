{express, async, _} = app.libs
{requireAdminAuthenticate} = app.middleware
{plaggable} = app
{Account, Ticket, Financials, CouponCode} = app.models

module.exports = exports = express.Router()

exports.use requireAdminAuthenticate

exports.get '/', (req, res) ->
  Account.find {}, (err, accounts) ->
    return res.render 'admin',
      accounts: accounts
      coupon_code_types: _.keys CouponCode.coupons_meta

exports.get '/ticket', (req, res) ->
  LIMIT = 10

  async.parallel
    pending: (callback) ->
      Ticket.find
        status: 'pending'
      , null,
        sort:
          updated_at: -1
      , callback

    open: (callback) ->
      Ticket.find
        status: 'open'
      , null,
        sort:
          updated_at: -1
        limit: LIMIT
      , callback

    finish: (callback) ->
      Ticket.find
        status: 'finish'
      , null,
        sort:
          updated_at: -1
        limit: LIMIT
      , callback

    closed: (callback) ->
      Ticket.find
        status: 'closed'
      , null,
        sort:
          updated_at: -1
        limit: LIMIT
      , callback

  , (err, result) ->
    res.render 'ticket/list', result

exports.post '/confirm_payment', (req, res) ->
  Account.findOne req.body.account_id, (err, account) ->
    unless account
      return res.error 'account_not_exist'

    amount = parseFloat req.body.amount

    if _.isNaN amount
      return res.error 'invalid_amount'

    account.incBalance amount, 'deposit',
      type: req.body.type
      order_id: req.body.order_id
    , ->
      res.json {}

exports.post '/delete_account', (req, res) ->
  Account.findOne req.body.account_id, (err, account) ->
    unless account
      return res.error 'account_not_exist'

    unless _.isEmpty account.billing.plans
      return res.error 'already_in_plan'

    unless account.attribute.balance <= 0
      return res.error 'balance_not_empty'

    Account.findByIdAndRemove account._id, ->
      res.json {}

exports.post '/generate_coupon_code', (req, res) ->
  coupon_code = _.pick req.body, 'expired', 'available_times', 'type', 'meta'

  CouponCode.createCodes coupon_code, req.body.count, (err, coupon_codes) ->
    res.json coupon_codes
