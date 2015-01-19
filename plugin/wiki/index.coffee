{fs, path} = app.libs
{pluggable, config} = app
{Plugin} = app.interfaces

wikiPlugin = module.exports = new Plugin
  name: 'wiki'

  register_hooks:
    'view.layout.menu_bar':
      href: '/wiki/'
      t_body: ''

  initialize: ->
    unless config.plugins.wiki?.disable_default_wiki
      wiki_path = "#{__dirname}/../../WIKI"

      for category_name in fs.readdirSync(wiki_path)
        for file_name in fs.readdirSync("#{wiki_path}/#{category_name}")
          @registerHook 'plugins.wiki.pages',
            category: category_name
            name: file_name
            t_category: category_name
            t_title: file_name
            language: 'zh_CN'
            content_markdown: fs.readFileSync("#{wiki_path}/#{category_name}/#{file_name}").toString()

      app.express.use '/wiki', require './router'
