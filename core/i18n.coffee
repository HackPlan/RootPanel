path = require 'path'
fs = require 'fs'
_ = require 'underscore'
acceptLanguage = require 'accept-language'

config = require '../config'

acceptLanguage.default config.i18n.default_language.replace('_', '-')

i18n_data = {}

for lang in config.i18n.available_language
  i18n_data[lang] = require "./locale/#{lang}"

exports.loadForPlugin = (plugin) ->
  for lang in options.available_language
    path = "../plugin/#{plugin.name}/locale/#{lang}.json"

    if fs.existsSync path
      i18n_data[lang]['plugins'][plugin.name] = require lang

exports.translate = (name, lang) ->
  unless lang
    lang = config.i18n.default_language

  keys = name.split '.'
  keys.unshift lang

  result = i18n_data

  for item in keys
    unless result[item] == undefined
      result = result[item]

  if result == undefined and lang != config.i18n.default_language
    return exports.translate name, config.i18n.default_language
  else if _.isObject result
    return name
  else
    return result

exports.getTranslator = (lang) ->
  return (name) ->
    return exports.translate name, lang

exports.initI18nData = (req, res, next) ->
  timezone_mapping =
    CN: 'Asia/Shanghai'
    TW: 'Asia/Taipei'
    HK: 'Asia/Hong_Kong'
    US: 'US/Aleutian'
    GB: 'Europe/London'

  if !req.cookies['language'] or req.cookies['timezone']
    result = acceptLanguage.parse req.headers['accept-language']

    language = result[0].language.toLowerCase()
    region = result[0].region.toUpperCase()

  unless req.cookies['language']
    locale_code = "#{language}_#{region}"

    req.cookies['language'] = locale_code
    res.cookie 'language', locale_code

  unless req.cookies['timezone']
    timezone = timezone_mapping[region]

    req.cookies['timezone'] = timezone
    res.cookie 'timezone', timezone

  next()

exports.downloadLocales = (req, res) ->
  language = req.params.language

  result = i18n_data[config.i18n.default_language]

  if language in config.i18n.available_language and language != config.i18n.default_language
    result = _.extend result, i18n_data[language]

  res.json result
