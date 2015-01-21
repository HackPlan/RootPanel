crypto = require 'crypto'
_ = require 'underscore'

exports.rx =
  username: /^[a-z][0-9a-z_]{2,23}$/
  email: /^\w+([-+.]\w+)*@\w+([-+.]\w+)*$/
  password: /^.+$/
  domain: /^(\*\.)?[A-Za-z0-9]+(\-[A-Za-z0-9]+)*(\.[A-Za-z0-9]+(\-[A-Za-z0-9]+)*)*$/
  filename: /^[A-Za-z0-9_\-\.]+$/
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
  return exports.sha256 password_salt + exports.sha256(password)

exports.wrapAsync = (func) ->
  return (callback) ->
    func (result) ->
      callback null, result

exports.pickErrorName = (error) ->
  unless error and error.errors
    return null

  if _.isEmpty error.errors
    return null

  err = error.errors[_.first(_.keys(error.errors))]

  if err.message == 'unique_validation_error'
    return "#{err.path}_exist"

  return err.message

exports.formatBillingTrigger = (name, plugin_name) ->
  [part1, part2] = name.split '.'

  if part2
    return name
  else
    return "#{plugin_name}.#{part1}"

exports.mongodbUri = (config) ->
  {user, password, host, name} = config

  if user and password
    return "mongodb://#{user}:#{password}@#{host}/#{name}"
  else
    return "mongodb://#{host}/#{name}"
