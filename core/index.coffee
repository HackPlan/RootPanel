express = require 'express'
i18next = require 'i18next'
path = require 'path'

config = require './config'
router = require './router'
db = require './db'

app = express()

i18next.init
  fallbackLng: config.i18n.defaultLanguage
  resGetPath: path.join(__dirname, 'locale/__lng__.json')

i18next.registerAppHelper app
app.use i18next.handle
app.use express.bodyParser()
app.use express.cookieParser()
app.use express.logger('dev')

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
