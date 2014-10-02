path = require 'path'
fs = require 'fs'
_ = require 'underscore'

stringify = require 'json-stable-stringify'

utils = require './utils'
cache = require './cache'
config = require '../config'

i18n_data = {}

for lang in config.i18n.available_language
  i18n_data[lang] = require "./locale/#{lang}"

exports.loadForPlugin = (plugin) ->
  for lang in config.i18n.available_language
    path = "../plugin/#{plugin.name}/locale/#{lang}.json"

    if fs.existsSync path
      i18n_data[lang]['plugins'][plugin.name] = require lang

exports.parseLanguageCode = parseLanguageCode = (language) ->
  [lang, country] = language.replace('-', '_').split '_'

  return {
    language: language
    lang: lang.toLowerCase()
    country: country.toUpperCase()
  }

exports.calcLanguagePriority = (req) ->
  negotiator = new Negotiator req
  language_info = parseLanguageCode req.cookies.language

  result = _.filter config.i18n.available_language, (i) ->
    return i.language == language_info.language

  result = _.union result, _.filter config.i18n.available_language, (i) ->
    return parseLanguageCode(i).lang == language_info.lang

  result = _.union result, _.filter config.i18n.available_language, (i) ->
    return parseLanguageCode(i).lang in negotiator.languages()

  result.push config.i18n.default_language

  result = _.union result, config.i18n.available_language

  return result

exports.translateByLanguage = (name, language) ->
  keys = name.split '.'
  keys.unshift language

  result = i18n_data

  for item in keys
    if result[item] == undefined
      return undefined
    else
      result = result[item]

  return result

exports.translate = (name, req) ->
  priority_order = exports.calcLanguagePriority req

  for language in priority_order
    result = exports.translateByLanguage name, language

    if result != undefined
      return result

  return name

exports.getTranslator = (req) ->
  return  (name, payload) ->
    result = exports.translate name, req

    if _.isObject payload
      for k, v of payload
        result = result.replace new RegExp("__#{k}__", 'g'), v

    return result

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

exports.pickClientLocale = (language) ->
  cached_result = cache.counter.get "client.locale:#{language}"

  if cached_result
    return cached_result

  result = i18n_data[config.i18n.default_language]

  if language in config.i18n.available_language and language != config.i18n.default_language
    result = _.extend result, i18n_data[language]

  cache.counter.set "client.locale:#{language}", result, NaN

  return result

exports.clientLocaleHash = (language) ->
  return utils.sha256 stringify exports.pickClientLocale language

exports.downloadLocales = (req, res) ->
  res.json exports.pickClientLocale req.params.language
