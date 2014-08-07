#!/usr/bin/env coffee

child_process = require 'child_process'
async = require 'async'
fs = require 'fs'

fs.readdir '/home', (err, files) ->
  throw err if err

  async.mapSeries files, (file, callback) ->
    async.parallel [
      (callback) ->
        child_process.exec "sudo chown -R #{file}:#{file} /home/#{file}", (err) ->
          callback err

      (callback) ->
        child_process.exec "sudo chmod -R o-rwx /home/#{file}", (err) ->
          callback err
    ], (err) ->
      throw err if err
      console.log "finish chown/chmod for #{file}"
      callback()
  , ->
    process.exit()
