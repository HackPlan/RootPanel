request = require 'request'

config = require './config'

exports.genAddress = (blockchain_secret, callback) ->
  callback_url = "#{config.web.url}/bitcoin/blockchain_callback?secret=#{blockchain_secret}"
  url = "https://blockchain.info/api/receive?method=create&address=#{config.bitcoin.forward_to}&callback=#{encodeURI(callback_url)}"

  request url, (err, res, body) ->
    body = JSON.parse body

    callback body.input_address
