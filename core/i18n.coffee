path = require 'path'
fs = require 'fs'

config = require '../config'

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

  keys = key.split '.'
  keys.unshift lang

  result = object

  for item in keys
    unless result[item] == undefined
      result = result[item]

  if result == undefined and lang != config.i18n.default_language
    return exports.translate name, config.i18n.default_language
  else
    return result

exports.getTranslator = (lang) ->
  return (name) ->
    return exports.translate name, lang
