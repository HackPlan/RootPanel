{Router} = require 'express'

{Component} = root

module.router = router = new Router()

router.use root.middleware.requireAuthenticate

router.param 'id', (req, res, next, componentId) ->
  Component.findById(componentId).done (component) ->
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
