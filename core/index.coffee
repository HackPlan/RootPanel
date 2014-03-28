express = require 'express'
i18next = require 'i18next'
path = require 'path'
fs = require 'fs'

config = require './config'
router = require './router'
db = require './db'

app = express()

i18next.init
  fallbackLng: config.i18n.defaultLanguage
  resGetPath: path.join(__dirname, 'locale/__lng__.json')

i18next.registerAppHelper app
app.use i18next.handle
app.use express.json()
app.use express.urlencoded()
app.use express.cookieParser()
app.use express.logger('dev')

app.locals.version = do ->
  logs = fs.readFileSync './.git/logs/HEAD', 'utf8'
  logs = logs.split "\n"
  lastline = logs[logs.length - 2]

  result = lastline.match /([a-f0-9]{40})\s([a-f0-9]{40})\s(\S+)\s(\S+)\s(\d+)\s(\+\d+)\s(.+)/

  version =
    parent: result[1]
    version: result[2]
    author: result[3]
    email: result[4]
    time: new Date parseInt(result[5]) * 1000
    timezone: result[6]
    message: result[7]

  return version

app.use (req, res, next) ->
  res.locals.app = app

  next()

app.use (req, res, next) ->
  if req.headers['x-token']
    req.token = req.headers['x-token']
  else
    req.token = req.cookies.token

  next()

app.use express.static(path.join(__dirname, 'static'))

app.set 'views', path.join(__dirname, 'view')
app.set 'view engine', 'jade'

db.connect ->
  router.bind(app)

  app.listen config.web.port
