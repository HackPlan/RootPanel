#!/usr/bin/env coffee

{MongoClient} = require 'mongodb'
semver = require 'semver'
async = require 'async'
path = require 'path'
fs = require 'fs'
_ = require 'underscore'

config = require '../config'

{user, password, host, name} = config.mongodb
mongodb_uri = "mongodb://#{user}:#{password}@#{host}/#{name}"

MongoClient.connect mongodb_uri, (err, db) ->
  throw err if err

  migrations = _.map fs.readdirSync("#{__dirname}/database"), (filename) ->
    return filename.match(/v(\d+\.\d+\.\d+)\.coffee/)[1]

  migrations.sort (a, b) ->
    if semver.gt a, b
      return 1

    if semver.lt a, b
      return -1

    return 0

  db.collection('options').findOne
    key: 'db_version'
  , (err, result) ->
    latest_version = require('../package.json').version
    current_version = result?.version ? latest_version

    async.eachSeries migrations, (migration, callback) ->
      if semver.gt(migration, current_version) and semver.lte(migration, latest_version)
        console.log "Running migration #{migration}..."

        require("#{__dirname}/database/v#{migration}.coffee") db, (err) ->
          return callback err if err

          db.collection('options').update
            key: 'db_version'
          ,
            key: 'db_version'
            version: migration
          ,
            upsert: true
          , (err) ->
            callback err

      else
        callback()

    , (err) ->
      if err
        throw err
      else
        console.log 'Migration Finish'
        process.exit 0
