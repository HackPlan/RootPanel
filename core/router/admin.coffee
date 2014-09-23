express = require 'express'
async = require 'async'
_ = require 'underscore'

{requireAdminAuthenticate, renderAccount} = require './../middleware'
{plaggable} = app
{mAccount, mTicket, mBalanceLog, mCouponCode} = app.models

module.exports = exports = express.Router()

exports.get '/', requireAdminAuthenticate, renderAccount, (req, res) ->
  mAccount.find().toArray (err, accounts) ->
    return res.render 'admin',
      accounts: accounts
      coupon_code_types: _.keys mCouponCode.type_meta

exports.get '/ticket', requireAdminAuthenticate, renderAccount, (req, res) ->
  async.parallel
    pending: (callback) ->
      mTicket.find
        status: 'pending'
      ,
        sort:
          updated_at: -1
      .toArray callback

    open: (callback) ->
      mTicket.find
        status: 'open'
      ,
        sort:
          updated_at: -1
        limit: 10
      .toArray callback

    finish: (callback) ->
      mTicket.find
        status: 'finish'
      ,
        sort:
          updated_at: -1
        limit: 10
      .toArray callback

    closed: (callback) ->
      mTicket.find
        status: 'closed'
      ,
        sort:
          updated_at: -1
        limit: 10
      .toArray callback

  , (err, result) ->
    res.render 'ticket/list',
      pending: result.pending
      open: result.open
      finish: result.finish
      closed: result.closed

exports.post '/create_payment', requireAdminAuthenticate, (req, res) ->
  mAccount.findId req.body.account_id, (err, account) ->
    unless account
      return res.error 'account_not_exist'

    amount = parseFloat req.body.amount

    if _.isNaN amount
      return res.error 'invalid_amount'

    mAccount.incBalance account, 'deposit', amount,
      type: req.body.type
      order_id: req.body.order_id
    , ->
      res.json {}

exports.post '/delete_account', requireAdminAuthenticate, (req, res) ->
  mAccount.findId req.body.account_id, (err, account) ->
    unless account
      return res.error 'account_not_exist'

    unless _.isEmpty account.attribute.plans
      return res.error 'aleady_in_plan'

    unless account.attribute.balance <= 0
      return res.error 'balance_not_empty'

    mAccount.remove _id: account._id, ->
      res.json {}

exports.post '/update_site', requireAdminAuthenticate, (req, res) ->
  mAccount.findOne
    'attribute.plugin.nginx.sites._id': new ObjectID req.body.site_id
  , (err, account) ->
    mAccount.update
      'attribute.plugin.nginx.sites._id': new ObjectID req.body.site_id
    ,
      $set:
        'attribute.plugin.nginx.sites.$.is_enable': if req.body.is_enable then true else false
    , ->
      pluggable.get('nginx').service.writeConfig account, ->
        res.json {}

exports.post '/generate_coupon_code', requireAdminAuthenticate, (req, res) ->
  coupon_code = _.pick req.body, 'expired', 'available_times', 'type', 'meta'

  mCouponCode.createCodes coupon_code, req.body.count, (coupon_codes) ->
    res.json coupon_codes
