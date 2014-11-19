{fs, path} = app.libs
{pluggable, config} = app

exports = module.exports = class WikiPlugin extends pluggable.Plugin
  @NAME: 'wiki'
  @type: 'extension'

exports.registerHook 'view.layout.menu_bar',
  href: '/wiki/'
  t_body: 'plugins.wiki.'

unless config.plugins.wiki?.disable_default_wiki
  wiki_path = "#{__dirname}/../../WIKI"

  for category_name in fs.readdirSync(wiki_path)
    for file_name in fs.readdirSync("#{wiki_path}/#{category_name}")
      exports.registerHook 'plugin.wiki.pages',
        t_category: category_name
        t_title: file_name
        language: 'zh_CN'
        content_markdown: fs.readFileSync("#{wiki_path}/#{category_name}/#{file_name}").toString()

app.express.use '/wiki', require './wiki'
