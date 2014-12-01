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
  lang = lang?.toLowerCase() ? null
  country = country?.toUpperCase() ? null

  return {
    language: language
    lang_country: if country then "#{lang}_#{country}" else lang
    lang: lang
    country: country
  }

i18n.getLanguagesByReq = getLanguagesByReq = (req) ->
  negotiator = new Negotiator req
  return _.uniq _.compact [req.cookies.language].concat negotiator.languages()

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
    result = exports.translate name, i18n.languagePriority languages

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
  result = []

  for language in languages
    {lang_country} = parseLanguageCode language
    for available_language in config.i18n.available_language
      if parseLanguageCode(available_language).lang_country == lang_country
        result.push lang_country

  for language in languages
    {lang, lang_country} = parseLanguageCode language
    for available_language in config.i18n.available_language
      if parseLanguageCode(available_language).lang == lang
        result.push lang_country

  result = _.union _.uniq(result), config.i18n.available_language

  return _.filter result, (i) -> i in config.i18n.available_language

, (languages) -> languages.join()

i18n.localeHash = (req) ->
  return utils.sha256 jsonStableStringify exports.pickClientLocale getLanguagesByReq req
