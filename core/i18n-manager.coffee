jsonStableStringify = require 'json-stable-stringify'
Negotiator = require 'negotiator'
path = require 'path'
fs = require 'fs'
_ = require 'lodash'

utils = require './utils'

###
  Manager: Internationalization manager,
  You can access a global instance via `root.i18n`.
###
module.exports = class I18nManager
  ###
    Private: Constructor

    * `config` {Object} `i18n` of config object

    This function will load all translations in `/core/locale` directory automatically.
  ###
  constructor: (@config) ->
    @translations = {}

    for filename in fs.readdirSync(path.join __dirname, 'locale')
      @addTranslations path.basename(filename, '.json'), require path.join(__dirname, 'locale', filename)

  ###
    Public: Add translations.

    * `language` {String}

  ###
  addTranslations: (language, translations) ->
    language = formatLanguage language
    @translations[language] ?= {}
    _.merge @translations[language], translations

  ###
    Public: Get all language names.

    Return {Array} of {String}.
  ###
  languages: ->
    return _.keys @translations

  ###
    Public: Get translator by language.

    * `language` {String}

    Return {Function} `(name, params) -> String`.
  ###
  translator: (language) ->
    return (name, params) ->
      return insert @translate(name, @alternativeLanguages language), params

  ###
    Public: Get translator by request.

    * `req` {ClientRequest}

    Return {Function} `(name, params) -> String`.
  ###
  translatorByReq: (req) ->
    return (name, params) ->
      return insert @translate(name, @alternativeLanguagesByReq req), params

  ###
    Public: Get packaged translations by language.

    * `language` {String}

    Return {Object}.
  ###
  packClientLocale: (language) ->
    return @packLocale @alternativeLanguages language

  ###
    Public: Get packaged translations by request.

    * `req` {ClientRequest}

    Return {Object}.
  ###
  packClientLocaleByReq: (req) ->
    return @packLocale @alternativeLanguagesByReq req

  ###
    Public: Get hash of packaged translations by language.

    * `language` {String}

    Return {Object}.
  ###
  localeHash: (language) ->
    utils.sha256 jsonStableStringify @pickClientLocale language

  ###
    Public: Get hash of packaged translations by request.

    * `req` {ClientRequest}

    Return {Object}.
  ###
  localeHashByReq: (req) ->
    utils.sha256 jsonStableStringify @pickClientLocaleByReq req

  ###
    Public: Translate name by languages.

    * `name` {String}
    * `languages` {Array} of {String}

    Return {String}.
  ###
  translate: (name, languages) ->
    for language in languages
      result = @translateByLanguage name, language

      if result != undefined
        return result

    return name

  ###
    Private: Translate name by specified language.

    * `name` {String}
    * `language` {String}

    Return {String}.
  ###
  translateByLanguage: (name, language) ->
    return '' unless name

    ref = @translations

    for word in [language, name.split('.')...]
      if ref[word] == undefined
        return undefined
      else
        ref = ref[word]

    return ref

  ###
    Private: Pack translations by languages.

    * `languages` {Array} of {String}

    Return {Object}.
  ###
  packLocale: (languages) ->
    result = {}

    for language in languages
      _.merge result, @translations[language]

    return result

  ###
    Private: Get alternative languages of specified language.

    * `language` {String}

    Return {Array} of {String}.
  ###
  alternativeLanguages: (language) ->
    {lang} = parseLanguage language

    alternatives = @languages().filter (language) ->
      return parseLanguage(language).lang == lang

    return _.uniq [language, alternatives..., @config.default_language]

  ###
    Private: Get alternative languages of request.

    * `req` {ClientRequest}

    Return {Array} of {String}.
  ###
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
