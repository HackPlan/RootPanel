exports.bind = (app) ->
  for item in ['account', 'panel', 'ticket']
    apiModule = require('./' + item)

    generateUrl = (name) ->
      if name[0] == '/'
        return name
      else
        return "/#{item}/#{name}/"

    for name, controller of apiModule.get
      app.get generateUrl(name), controller

    for name, controller of apiModule.post
      app.post generateUrl(name), controller
