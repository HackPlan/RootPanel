{_, express} = app.libs
{logger} = app
{requireAuthenticate} = app.middleware
{Component} = app.models

module.exports = exports = express.Router()

exports.use requireAuthenticate

componentParam = (req, res, next, id) ->
  Component.findById id, (err, component) ->
    logger.error err if err

    unless component
      return res.error 404, 'component_not_found'

    unless component.hasMember req.account
      unless req.account.isAdmin()
        return res.error 403, 'component_forbidden'

    _.extend req,
      component: component

    next()

exports.use '/resource', do ->
  rest = new express.Router mergeParams: true
  rest.param 'id', componentParam

  rest.get '/', (req, res) ->
    Component.getComponents req.account, (err, components) ->
      if err
        res.error err
      else
        res.json components

  rest.post '/', (req, res) ->

  rest.get '/:id', (req, res) ->

  rest.patch '/:id', (req, res) ->

  rest.delete '/:id', (req, res) ->
