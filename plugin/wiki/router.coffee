{markdown, path, jade, fs, _, express} = app.libs
{pluggable} = app

wikiPlugin = null

process.nextTick ->
  wikiPlugin = require './index'

module.exports = exports = express.Router()

exports.get '/', (req, res) ->
  pages_by_category = {}

  for page in pluggable.applyHooks 'plugins.wiki.pages'
    pages_by_category[page.category] ?= []
    pages_by_category[page.category].push page

  categories = []

  for category, pages of pages_by_category
    categories.push
      t_name: _.first(pages).t_category
      name: category
      pages: pages

  wikiPlugin.render 'index', req, {categories: categories}, (html) ->
    res.send html

exports.get '/:category/:name', (req, res) ->
  page = _.findWhere pluggable.applyHooks('plugins.wiki.pages'),
    category: req.params.category
    name: req.params.name

  unless page
    return res.status(404).end()

  console.log page

  view_data =
    title: page.plugin.getTranslator(req) page.t_title
    content: markdown.toHTML page.content_markdown

  wikiPlugin.render 'page', req, view_data, (html) ->
    res.send html
