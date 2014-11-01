{markdown, path, jade, fs, _, express} = app.libs
{pluggable} = app

wiki_plugin = require './index'

module.exports = exports = express.Router()

exports.get '/', (req, res) ->
  pages = pluggable.selectHook req.account, 'plugin.wiki.pages'

  pages_by_category = {}

  for page in pages
    page.title = res.t page.t_title

    pages_by_category[page.t_category] ?= []
    pages_by_category[page.t_category].push page

  result = []

  for category_name, pages of pages_by_category
    result.push
      t_category: category_name
      category: res.t category_name
      pages: pages

  view_data = _.extend res.locals,
    category_list: result

  wiki_plugin.render 'index', req, view_data, (html) ->
    res.send html

exports.get '/:category/:title', (req, res) ->
  matched_page = _.findWhere pluggable.selectHook(req.account, 'plugin.wiki.pages'),
    t_category: req.params.category
    t_title: req.params.title

  unless matched_page
    return res.status(404).end()

  view_data = _.extend res.locals,
    title: res.t matched_page.t_title
    content: markdown.toHTML matched_page.content_markdown

  wiki_plugin.render 'page', req, view_data, (html) ->
    res.send html
