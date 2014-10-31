child_process = require 'child_process'
async = require 'async'
fs = require 'fs'
_ = require 'underscore'

async.eachSeries fs.readdirSync("#{__dirname}/../sample"), (filename, callback) ->
  fs.writeFileSync "#{__dirname}/../config.coffee", fs.readFileSync "#{__dirname}/../sample/#{filename}"

  console.log "Config: #{filename}"

  proc = child_process.spawn "#{__dirname}/../node_modules/.bin/mocha", '--compilers coffee:coffee-script/register
    --require test/env --reporter test/reporter-cov-summary.js --
    core/test/*.test.coffee core/test/*/*.test.coffee'.split(' '),
    env: _.extend process.env,
      COV_TEST: 'true'

  proc.stdout.pipe process.stdout
  proc.stderr.pipe process.stderr

  proc.on 'close', (code) ->
    if code
      process.exit code
    else
      callback()

, ->
  process.exit 0
