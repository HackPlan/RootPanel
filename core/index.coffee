express = require 'express'
i18next = require 'i18next'
path = require 'path'

config = require './config'
router = require './router'

app = express()

i18next.init
  fallbackLng: config.i18n.defaultLanguage
  resGetPath: path.join(__dirname, 'locale/__lng__.json')

i18next.registerAppHelper(app);
app.use(i18next.handle);

app.use express.static(path.join(__dirname, 'static'))

app.set 'views', path.join(__dirname, 'view')
app.set 'view engine', 'jade'

for url, controller of router.get
  app.get url, controller

for url, controller of router.post
  app.post url, controller

app.listen config.web.port
