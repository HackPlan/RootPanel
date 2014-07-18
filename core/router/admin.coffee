{requestAdminAuthenticate, renderAccount} = require './middleware'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.get '/', requestAdminAuthenticate, renderAccount, (req, res) ->
  mAccount.find().toArray (err, accounts) ->
    res.render 'admin/index',
      accounts: accounts

exports.post '/create_payment', requestAdminAuthenticate, (req, res) ->
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
