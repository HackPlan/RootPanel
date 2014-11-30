{path, fs, _, Negotiator, jsonStableStringify} = app.libs
{utils, cache, config} = app

i18n = exports

i18n.i18n_data = i18n_data = {}

i18n.init = ->
  for filename in fs.readdirSync path.join(__dirname, 'locale')
    language = path.basename filename, '.json'
    i18n_data[language] = require path.join(__dirname, 'locale', filename)
    config.i18n.available_language = _.union config.i18n.available_language, [language]

i18n.initPlugin = (plugin) ->
  for filename in fs.readdirSync path.join(__dirname, '../plugin', plugin.name, 'locale')
    language = path.basename filename, '.json'
    file_path = path.join __dirname, '../plugin', plugin.name, 'locale', filename

    i18n_data[language] ?= {}
    i18n_data[language]['plugins'] ?= {}
    i18n_data[language]['plugins'][plugin.name] = require file_path

    config.i18n.available_language = _.union config.i18n.available_language, [language]

i18n.parseLanguageCode = parseLanguageCode = (language) ->
  [lang, country] = language.replace('-', '_').split '_'

  return {
    language: language
    lang: lang?.toLowerCase()
    country: country?.toUpperCase()
  }

i18n.getLanguagesByReq = getLanguagesByReq = (req) ->
  negotiator = new Negotiator req
  return [req.cookies.language].concat negotiator.languages()

i18n.translateByLanguage = (name, language) ->
  return '' unless name

  words = name.split '.'
  words.unshift language

  result = i18n_data

  for item in words
    if result[item] == undefined
      return undefined
    else
      result = result[item]

  return result

i18n.translate = (name, languages) ->
  for language in languages
    result = i18n.translateByLanguage name, language

    if result != undefined
      return result

  return name

i18n.getTranslator = (languages) ->
  return (name, payload) ->
    result = exports.translate name, languages

    if _.isObject payload
      for k, v of payload
        result = result.replace new RegExp("__#{k}__", 'g'), v

    return result

i18n.getTranslatorByReq = (req) ->
  return i18n.getTranslator getLanguagesByReq req

i18n.pickClientLocale = _.memoize (languages) ->
  result = {}

  for language in languages
    _.extend result, i18n_data[language]

  return result

, (languages) -> languages.join()

i18n.languagePriority = _.memoize (languages) ->
  result = _.filter languages, (language) ->
    return language in config.i18n.available_language

  result = _.union result, _.filter languages, (language) ->
    for available_language in config.i18n.available_language
      if parseLanguageCode(available_language).lang == parseLanguageCode(language).lang
        return true

  return _.union result, config.i18n.available_language

, (languages) -> languages.join()

i18n.localeHash = (req) ->
  return utils.sha256 jsonStableStringify exports.pickClientLocale getLanguagesByReq req
