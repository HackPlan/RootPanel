express = require 'express'

{requireAdminAuthenticate, renderAccount} = require './../middleware'
{plaggable} = app
{mAccount, mTicket, mBalance} = app.models

module.exports = exports = express.Router()

exports.get '/', requireAdminAuthenticate, renderAccount, (req, res) ->
  mBalance.find
    type: 'service_billing'
    'attribute.service': 'shadowsocks'
    created_at:
      $gte: new Date Date.now() - 30 * 24 * 3600 * 1000
  .toArray (err, balance_logs) ->
    time_range =
      traffic_24hours: 24 * 3600 * 1000
      traffic_3days: 3 * 24 * 3600 * 1000
      traffic_7days: 7 * 24 * 3600 * 1000
      traffic_30days: 30 * 24 * 3600 * 1000

    traffic_result = {}

    for name, range of time_range
      logs = _.filter balance_logs, (i) ->
        return i.created_at.getTime() > Date.now() - range

      traffic_result[name] = _.reduce logs, (memo, i) ->
        return memo + i.attribute.traffic_mb
      , 0

    mAccount.find().toArray (err, accounts) ->
      sites = []

      pending_traffic = 0

      for account in accounts
        if account.attribute.plugin?.nginx?.sites
          for site in account.attribute.plugin.nginx.sites
            sites.push _.extend site,
              account: account

        account.traffic_30days = _.reduce balance_logs, (memo, item) ->
          if item.account_id.toString() == account._id.toString()
            return memo + item.attribute.traffic_mb
          else
            return memo
        , 0

        if account.attribute.plugin.shadowsocks?.pending_traffic
          pending_traffic += account.attribute.plugin.shadowsocks.pending_traffic

      res.render 'admin/index', _.extend traffic_result,
        accounts: accounts
        sites: sites
        pending_traffic: pending_traffic
        siteSummary: pluggable.get('nginx').service.siteSummary

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
