{Router} = require 'express'

{Component} = root
{requireAuthenticate} = require '../middleware'

module.exports = router = new Router()

router.use requireAuthenticate

router.param 'id', (req, res, next, component_id) ->
  Component.findById(component_id).done (component) ->
    unless req.component = component
      return next new Error 'component not found'

    unless component.hasMember req.account
      unless req.account.isAdmin()
        return next new Error 'component forbidden'

    next()
  , next

###
  Router: GET /components

  Response {Array} of {Component}.
###
router.get '/', (req, res, next) ->
  Component.getComponents(req.account).done (components) ->
    res.json components
  , next

###
  Router: POST /components/:type

  Response {Component}.
###
router.post '/:type', (req, res, next) ->
  {account, params: {type}, body: {name, options}} = req

  unless type in root.billing.availableComponents(account)
    next new Error 'component_not_available'

  root.components.byName(type).create account, root.servers.master(),
    name: name
    options: options
  .done (component) ->
    res.send component
  , next

###
  Router: PATCH /components/:id

  Response {Component}.
###
router.patch '/:id', (req, res) ->

###
  Router: DELETE /components/:id
###
router.delete '/:id', (req, res, next) ->
  req.component.destroy().done ->
    res.sendStatus 204
  , next

router.all '/:id/actions/:action', (req, res) ->
