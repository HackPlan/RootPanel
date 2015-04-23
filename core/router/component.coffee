{Router} = require 'express'

{Component} = root
{requireAuthenticate} = require '../middleware'

module.exports = router = new Router()

router.use requireAuthenticate

router.param 'id', (req, res, next, component_id) ->
  Component.findById(component_id).done (component) ->
    unless req.component = component
      return res.error 404, 'component_not_found'

    unless component.hasMember req.account
      unless req.account.isAdmin()
        return res.error 403, 'component_forbidden'

    next()
  , res.error

###
  Router: GET /components

  Response {Array} of {Component}.
###
router.get '/', (req, res) ->
  Component.getComponents(req.account).done (components) ->
    res.json components
  , res.error

###
  Router: POST /components/:type

  Response {Component}.
###
router.post '/:type', (req, res) ->

###
  Router: PATCH /components/:id

  Response {Component}.
###
router.patch '/:id', (req, res) ->

###
  Router: DELETE /components/:id
###
router.delete '/:id', (req, res) ->

router.all '/:id/actions/:action', (req, res) ->
