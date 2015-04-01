{express} = app.libs
{logger} = app
{requireAuthenticate} = app.middleware
{Component} = app.models

module.exports = exports = express.Router()

exports.use requireAuthenticate

exports.use '/rest', do ->
  rest.param 'id', (req, res, next, component_id) ->
    Component.findById(component_id).then (component) ->
      _.extend req,
        component: component

      unless component
        return res.error 404, 'component_not_found'

      unless component.hasMember req.account
        unless req.account.isAdmin()
          return res.error 403, 'component_forbidden'

      next()

    .catch res.error

  rest.get '/', (req, res) ->
    Component.getComponents(req.account).done (components) ->
      res.json components
    , res.error

  rest.post '/', (req, res) ->

  rest.get '/:id', (req, res) ->

  rest.patch '/:id', (req, res) ->

  rest.delete '/:id', (req, res) ->
