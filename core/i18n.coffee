fs = require 'fs'

options =
  default_language: null
  available_language: []

data = {}

exports.init = (data) ->
  options = data

exports.load = (path) ->
  for lang in options.available_language
    data[lang] = JSON.parse fs.readFileSync((require 'path').join(path, "#{lang}.json"), 'utf8')

exports.loadPlugin = (path, name) ->
  for lang in options.available_language
    data[lang]['plugins'][name] = JSON.parse fs.readFileSync((require 'path').join(path, "#{lang}.json"), 'utf8')

exports.translate = (name, lang) ->
  unless lang
    lang = options.default_language

  names = name.split '.'
  result = data[lang][names.shift()]

  for item in names
    if result and result[item]
      result = result[item]
    else
      return name

  return result

exports.getTranslator = (lang) ->
  return (name) ->
    return exports.translate name, lang
