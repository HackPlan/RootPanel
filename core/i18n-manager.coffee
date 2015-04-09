jsonStableStringify = require 'json-stable-stringify'
Negotiator = require 'negotiator'
path = require 'path'
fs = require 'fs'
_ = require 'lodash'

utils = require './utils'

module.exports = class I18nManager
  constructor: (@config) ->
    @translations = {}

    for filename in fs.readdirSync(path.join __dirname, 'locale')
      @addTranslations path.basename(filename, '.json'), require path.join(__dirname, 'locale', filename)

  addTranslations: (language, translations) ->
    language = formatLanguage language
    @translations[language] ?= {}
    _.merge @translations[language], translations

  languages: ->
    return _.keys @translations

  translator: (language) ->
    return (name, params) ->
      return insert @translate(name, @alternativeLanguages language), params

  translatorByReq: (req) ->
    return (name, params) ->
      return insert @translate(name, @alternativeLanguagesByReq req), params

  packClientLocale: (language) ->
    return @packLocale @alternativeLanguages language

  packClientLocaleByReq: (req) ->
    return @packLocale @alternativeLanguagesByReq req

  localeHash: (language) ->
    utils.sha256 jsonStableStringify @pickClientLocale language

  localeHashByReq: (req) ->
    utils.sha256 jsonStableStringify @pickClientLocaleByReq req

  translate: (name, languages) ->
    for language in languages
      result = @translateByLanguage name, language

      if result != undefined
        return result

    return name

  translateByLanguage: (name, language) ->
    return '' unless name

    ref = @translations

    for word in [language, name.split('.')...]
      if ref[word] == undefined
        return undefined
      else
        ref = ref[word]

    return ref

  packLocale: (languages) ->
    result = {}

    for language in languages
      _.merge result, @translations[language]

    return result

  alternativeLanguages: (language) ->
    {lang} = parseLanguage language

    alternatives = @languages().filter (language) ->
      return parseLanguage(language).lang == lang

    return _.uniq [language, alternatives..., @config.default_language]

  alternativeLanguagesByReq: (req) ->
    return _.uniq _.compact [req.cookies?.language, (new Negotiator req).languages()...]

insert = (string, params) ->
  if _.isObject params
    for name, value of params
      string = string.replace new RegExp("{#{name}}", 'g'), value

  return string

parseLanguage = (language) ->
  [lang, country] = language.replace('_', '-').split '-'

  return {
    lang: lang?.toLowerCase()
    country: country?.toUpperCase()
  }

formatLanguage = (language) ->
  {lang, country} = parseLanguage language
  return "#{lang}-#{country}"
