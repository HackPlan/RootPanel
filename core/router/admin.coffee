{requireAdminAuthenticate, renderAccount} = require './middleware'

mAccount = require '../model/account'
mTicket = require '../model/ticket'

module.exports = exports = express.Router()

exports.get '/', requireAdminAuthenticate, renderAccount, (req, res) ->
  mAccount.find().toArray (err, accounts) ->
    res.render 'admin/index',
      accounts: accounts

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
        status: 'open'
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
