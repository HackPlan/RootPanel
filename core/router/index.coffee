exports.bind = (app) ->
  for item in ['user']
    apiModule = require('./' + item)

    for name, controller of apiModule.get
      name = name ? name + "/"
      app.all "/#{item}/#{name}", controller

    for name, controller of apiModule.post
      name = name ? name + "/"
      app.post "/#{item}/#{name}", controller
