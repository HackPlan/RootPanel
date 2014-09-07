crypto = require 'crypto'

exports.rx =
  username: /^[a-z][0-9a-z_]{2,23}$/
  email: /^\w+([-+.]\w+)*@\w+([-+.]\w+)*$/
  password: /^.+$/
  domain: /(\*\.)?[A-Za-z0-9]+(\-[A-Za-z0-9]+)*(\.[A-Za-z0-9]+(\-[A-Za-z0-9]+)*)*/
  filename: /[A-Za-z0-9_\-\.]+/
  url: /^https?:\/\/[^\s;]*$/

exports.sha256 = (data) ->
  if data
    return crypto.createHash('sha256').update(data).digest('hex')
  else
    return null

exports.md5 = (data) ->
  if data
    return crypto.createHash('md5').update(data).digest('hex')
  else
    return null

exports.randomSalt = ->
  return exports.sha256 crypto.randomBytes 256

exports.randomString = (length) ->
  char_map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

  result = _.map _.range(0, length), ->
    return char_map.charAt Math.floor(Math.random() * char_map.length)

  return result.join ''

exports.hashPassword = (password, password_salt) ->
  return exports.sha256(password_salt + exports.sha256(password))

exports.checkHomeFilePath = (account, path) ->
  home_dir = "/home/#{account.username}/"

  unless /^[/A-Za-z0-9_\-\.]+\/?$/.test path
    return false

  unless path.slice(0, home_dir.length) == home_dir
    return false

  unless path.length < 512
    return false

  unless path.slice(-3) != '/..'
    return false

  unless path.indexOf('/../') == -1
    return false

  return true

exports.checkHomeUnixSocket = (account, path) ->
  fastcgi_prefix = 'unix://'

  unless path.slice(0, fastcgi_prefix.length) == fastcgi_prefix
    return false

  unless exports.checkHomeFilePath account, path.slice fastcgi_prefix.length
    return false

  return true