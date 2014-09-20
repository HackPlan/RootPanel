#!/usr/bin/env coffee

_ = require 'underscore'
async = require 'async'
{MongoClient} = require 'mongodb'

config = require '../config'
{user, password, host, name} = config.mongodb
mongodb_uri = "mongodb://#{user}:#{password}@#{host}/#{name}"

version = _.last process.argv

migration_action =
  '0.7.1': (callback) ->
    ###
      npm install coffee-script -g

      vi /etc/rc.local

          iptables-restore < /etc/iptables.rules

      vi /etc/supervisor/conf.d/rpadmin.conf

          [program:RootPanel]
          command=node /home/rpadmin/RootPanel/start.js
          autorestart=true
          user=rpadmin

      service supervisor restart
    ###

    crypto = require 'crypto'
    bitcoin = require '../core/bitcoin'

    MongoClient.connect mongodb_uri, (err, db) ->
      mAccount = db.collection 'accounts'

      mAccount.find().toArray (err, accounts) ->
        async.each accounts, (account, callback) ->
          bitcoin_secret = crypto.createHash('sha256').update(crypto.randomBytes(256)).digest('hex')

          bitcoin.genAddress bitcoin_secret, (address) ->
            mAccount.update {_id: account._id},
              $set:
                'attribute.bitcoin_deposit_address': address
                'bitcoin_secret': bitcoin_secret
            , (err) ->
              callback err

        , (err) ->
          throw err if err
          console.log "[account.attribute.bitcoin_secret] update #{accounts.length} rows"
          callback()

  '0.6.0': (callback) ->
    MongoClient.connect mongodb_uri, (err, db) ->
      mAccount = db.collection 'accounts'

      async.parallel [
        (callback) ->
          mAccount.update
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
      ], (err) ->
        throw err if err
        callback()

if migration_action[version]
  migration_action[version] ->
    console.log "Finish migration to #{version}"
    process.exit()
else
  throw new Error 'Unknown Version'
