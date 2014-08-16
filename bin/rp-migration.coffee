#!/usr/bin/env coffee

_ = require 'underscore'
async = require 'async'
{MongoClient} = require 'mongodb'

config = require '../config'

base_version = _.last process.argv

migration_action =
  '0.6.0': (callback) ->
    {user, password, host, name} = config.mongodb
    MongoClient.connect "mongodb://#{user}:#{password}@#{host}/#{name}", (err, db) ->
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

if migration_action[base_version]
  migration_action[base_version] ->
    console.log "Finish migration from #{base_version}"
    process.exit()
else
  throw new Error 'Unknown Version'
