markdown = require('markdown').markdown
fs = require 'fs'
path = require 'path'

service = require './service'
{renderAccount, requireInService, requireAuthenticate} = require '../../core/middleware'

mAccount = require '../../core/model/account'

module.exports = exports = express.Router()

exports.use requireInService 'shadowsocks'

exports.post '/reset_password', (req, res) ->
  password = mAccount.randomString 10

  mAccount.update _id: req.account._id,
    $set:
      'attribute.plugin.shadowsocks.password': password
  , ->
    req.account.attribute.plugin.shadowsocks.password = password

    service.restart req.account, ->
      service.restartAccount req.account, ->
        res.json {}

wiki_router = express.Router()

wiki_router.use renderAccount, requireAuthenticate, (req, res) ->
  url = req.url.substr 1

  unless url
    url = 'README.md'

  filename = path.resolve path.join __dirname, 'WIKI', url
  baseDir = path.resolve path.join __dirname, 'WIKI'

  unless filename[0 .. baseDir.length-1] == baseDir
    return res.json 404

  fs.readFile filename, (err, data) ->
    if err
      return res.status(404).send err.toString()

    res.render 'wiki',
      title: url
      content: markdown.toHTML data.toString()

app.view_hook.menu_bar.push
  href: '/wiki/'
  html: '使用帮助'

app.use '/wiki', wiki_router
