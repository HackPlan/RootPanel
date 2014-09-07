markdown = require('markdown').markdown
path = require 'path'
fs = require 'fs'

{pluggable} = app
{renderAccount} = app.middleware

module.exports =
  name: 'wiki'
  type: 'extension'

pluggable.hooks.view.layout.menu_bar.push
  href: '/wiki/'
  body: '用户手册'

app.use '/wiki', renderAccount, (req, res) ->
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
