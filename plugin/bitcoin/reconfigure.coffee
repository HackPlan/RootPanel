{utils} = app
{Account} = app.models

bitcoin = require './bitcoin'

module.exports = (callback) ->
  Account.find
    'pluggable.bitcoin.bitcoin_deposit_address':
      $exists: false
  , (err, accounts) ->
    async.eachSeries accounts, (account, callback) ->
      bitcoin_secret = utils.randomSalt()

      console.log "create bitcoin_address for #{account.username}"

      bitcoin.genAddress bitcoin_secret, (address) ->
        account.update
          $set:
            'pluggable.bitcoin.bitcoin_deposit_address': address
            'pluggable.bitcoin.bitcoin_secret': bitcoin_secret
        , callback

    , (err) ->
      throw err if err
      callback()
