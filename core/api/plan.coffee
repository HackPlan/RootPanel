_ = require 'underscore'

config = require '../config'
api = require './index'

mAccount = require '../model/account'

module.exports =
  post:
    subscribe: (req, res) ->

    unsubscribe: (req, res) ->
