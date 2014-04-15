exports.bind = (app) ->
  for item in ['account', 'panel', 'ticket']
    apiModule = require('./' + item)

    generateUrl = (name) ->
      if name[0] == '/'
        return name
      else
        return "/#{item}/#{name}/"

    buildGetController = (controller) ->
      return (req, res) ->
        if req.method == 'GET'
          req.body = req.query

        return controller req, res

    for name, controller of apiModule.get
      app.get generateUrl(name), buildGetController controller

    for name, controller of apiModule.post
      app.post generateUrl(name), controller
