config = require '../../config'
plugin = require '../plugin'
bitcoin = require '../bitcoin'

mAccount = require '../model/account'

module.exports = exports = express.Router()

exports.post '/coinbase_callback', (req, res) ->
  mAccount.byDepositAddress req.body.address, (err, account) ->
    unless account
      return res.send 400, 'Invalid Address'

    unless req.query.secret == account.attribute.bitcoin_secret
      return res.send 400, 'Invalid Secret'

    bitcoin.getExchangeRate (rate) ->
      amount = req.body.amount / rate

      mAccount.incBalance account, 'deposit', amount,
        type: 'bitcoin'
        order_id: req.body.transaction.hash
      , ->
        res.send 'Success'
