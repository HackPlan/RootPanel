path = require 'path'
fs = require 'fs'

{pluggable} = app

wiki = require './wiki'

module.exports = pluggable.createHelpers exports =
  name: 'wiki'
  type: 'extension'

exports.registerHook 'view.layout.menu_bar',
  href: '/wiki/'
  t_body: 'plugins.wiki.'

for category_name in fs.readdirSync("#{__dirname}/../../WIKI")
  for file_name in fs.readdirSync("#{__dirname}/../../WIKI/#{category_name}")
    exports.registerHook 'plugin.wiki.pages',
      t_category: category_name
      t_title: file_name
      language: 'zh_CN'
      content_markdown: fs.readFileSync("#{__dirname}/../../WIKI/#{category_name}/#{file_name}").toString()

app.get '/wiki', wiki.index

app.get '/wiki/:category/:title', wiki.page
