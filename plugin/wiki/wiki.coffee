markdown = require('markdown').markdown
path = require 'path'
jade = require 'jade'
fs = require 'fs'

{pluggable} = app

exports.index = (req, res) ->
  pages = pluggable.selectHook req.account, 'plugin.wiki.pages'

  pages_by_category = {}

  for page in pages
    page.title = res.t page.t_title

    pages_by_category[page.t_category] ?= []
    pages_by_category[page.t_category].push page

  result = []

  for category_name, pages of pages_by_category
    result.push
      category: res.t category_name
      pages: pages

  jade.renderFile "#{__dirname}/view/index.jade",
    category_list: result

exports.page = (req, res) ->
  url = req.url.substr '/wiki'.length

  unless url
    url = 'README.md'

  filename = path.resolve path.join __dirname, '../../WIKI', url
  baseDir = path.resolve path.join __dirname, '../../WIKI'

  unless filename[0 .. baseDir.length - 1] == baseDir
    return res.status(403).end()

  fs.readFile filename, (err, data) ->
    if err
      return res.status(404).send err.toString()
    res.render 'wiki',
      title: url
      content: markdown.toHTML data.toString()
