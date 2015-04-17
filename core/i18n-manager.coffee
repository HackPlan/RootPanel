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
    * `translations` {Object}

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
    Public: Create translator by language or request.

    * `language` {String} or {ClientRequest}
    * `prefixes` {Array} or {String}

    Return {Function} `(name, params) -> String`.
  ###
  translator: (language, prefixes) ->
    translator = (name, params) =>
      return insert @translate(name, @alternativeLanguages language), params

    insert = (string, params) ->
      if _.isObject params
        for name, value of params
          string = string.replace new RegExp("\\{#{name}\\}", 'g'), value

      return string

    return (name) ->
      for prefix in [prefixes..., null]
        if prefix
          full_name = "#{prefix}.#{name}"
        else
          full_name = name

        result = translator full_name, [arguments...][1 ..]...

        if result != full_name
          return result

      return name

  ###
    Public: Get packaged translations by language or request.

    * `language` {String} or {ClientRequest}

    Return {Object}.
  ###
  packTranslations: (language) ->
    return @packTranslationsByLanguages @alternativeLanguages language

  ###
    Public: Get hash of packaged translations by language or request.

    * `language` {String} or {ClientRequest}

    Return {Object}.
  ###
  translationsHash: (language) ->
    utils.sha256 jsonStableStringify @packTranslations language

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
    return undefined unless name

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

    TODO: Cache.

    Return {Object}.
  ###
  packTranslationsByLanguages: (languages) ->
    result = {}

    for language in languages
      _.merge result, @translations[language]

    return result

  ###
    Private: Get alternative languages of specified language or request.

    * `language` {String} or {ClientRequest}

    Return {Array} of {String}.
  ###
  alternativeLanguages: (language) ->
    if _.isString language
      {lang} = parseLanguage language

      alternatives = @languages().filter (language) ->
        return parseLanguage(language).lang == lang

      return _.uniq [language, alternatives..., @config.default_language]

    else
      return _.uniq _.compact [req.cookies?.language, (new Negotiator language).languages()...]

parseLanguage = (language) ->
  [lang, country] = language.replace('_', '-').split '-'

  return {
    lang: lang?.toLowerCase()
    country: country?.toUpperCase()
  }

formatLanguage = (language) ->
  {lang, country} = parseLanguage language

  if country
    return "#{lang}-#{country}"
  else
    return lang
