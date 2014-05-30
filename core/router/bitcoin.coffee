express = require 'express'
async = require 'async'

config = require '../config'
plugin = require '../plugin'

module.exports = exports = express.Router()

exports.get '/blockchain_callback', (req, res) ->
