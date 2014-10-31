module.exports = (db, callback) ->
  cAccount = db.collection 'accounts'

  cAccount.update
    'tokens.available':
      $exists: true
  ,
    $unset:
      'tokens.$.available': true
  ,
    multi: true
  , (err, rows) ->
    console.log "[accounts.tokens.available] update #{rows} rows"
    callback err
