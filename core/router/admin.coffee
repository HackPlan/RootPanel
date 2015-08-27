{Router} = require 'express'
React = require 'react'
_ = require 'lodash'
Q = require 'q'

{Account, Ticket, Financials, CouponCode, Component} = root
{requireAdminAuthenticate} = require '../middleware'

module.exports = router = new Router()

router.use requireAdminAuthenticate

###
  Router: GET /admin/dashboard

  Response HTML.
###
router.get '/dashboard', (req, res, next) ->
  Q.all([
    Account.find()
    Component.find()
    Ticket.getTicketsGroupByStatus
      opening:
        limit: 10
      finished:
        limit: 10
      closed:
        limit: 10
    Q.all root.billing.all().map (plan) ->
      plan.membersInPlan().then (accounts) ->
        return {
          name: plan.name
          count: accounts.length
        }
    .then (result) ->
      return _.mapValues _.indexBy(result, 'name'), 'count'
  ]).done ([accounts, components, tickets, accountsInPlan]) ->
    props =
      accounts: accounts.map (account) ->
        return _.extend account, _id: account._id.toString()
      components: components.map (component) ->
        return _.extend component,
          _id: component._id.toString()
          account_id: component.account_id.toString()
      tickets: tickets
      package: root.package
      plans: root.billing.all().map (plan) ->
        plan = _.extend {}, plan,
          users: accountsInPlan[plan.name]
        return _.pick plan, 'components', 'join_freely', 'billing', 'name', 'users'
      plugins: root.plugins.all().map (plugin) ->
        return _.extend {}, _.pick(plugin, 'dependencies', 'name'),
          registered: do ->
            {routers, hooks, views, widgets, components, couponTypes, paymentProviders} = root.plugins.getRegisteredExtends plugin

            return {
              routers: _.pluck routers, 'path'
              hooks: _.pluck hooks, 'path'
              views: _.pluck views, 'view'
              widgets: _.pluck widgets, 'view'
              components: _.pluck components, 'name'
              couponTypes: _.pluck couponTypes, 'name'
              paymentProviders: _.pluck paymentProviders, 'name'
            }

    res.render 'admin/layout',
      mainBlock: React.renderToString React.createElement require('../view/admin/dashboard.jsx'), props
      initializeProps: props
  , next

###
  Router: POST /admin/coupons/generate

  Response {Array} of {CouponCode}.
###
router.post '/coupons/generate', (req, res, next) ->
  CouponCode.createCodes(req.body, req.body.count).done (coupons) ->
    res.json coupons
  , next

router.use '/users', do (router = new Router) ->
  router.param 'id', (req, res, next, user_id) ->
    Account.findById(user_id).then (user) ->
      if req.user = user
        next()
      else
        next new Error 'user not found'
    .catch next

  router.param 'plan', (req, res, next, plan_name) ->
    if req.plan = root.billing.byName plan_name
      next()
    else
      next new Error 'plan not found'

  ###
    Router: GET /admin/users/:id

    Response {Account}.
  ###
  router.get '/:id', (req, res) ->
    res.json req.user.pick 'admin'

  ###
    Router: POST /admin/users/:id/plans/join

    Request {Object}

      * `plan` {String}

  ###
  router.post '/:id/plans/join', (req, res, next) ->
    root.billing.byName(req.body.plan).addMember(req.user).done ->
      res.json req.user
    , next

  ###
    Router: POST /admin/users/:id/plans/leave

    Request {Object}

      * `plan` {String}

  ###
  router.post '/:id/plans/leave', (req, res, next) ->
    root.billing.byName(req.body.plan).removeMember(req.user).done ->
      res.json req.user
    , next

  ###
    Router: POST /admin/users/:id/deposits/create

    Request {Object}

      * `amount` {Number}
      * `provider` {String}
      * `orderId` {String}
      * `status` (optional) {String}

    Response {Financials}.
  ###
  router.post '/:id/deposits/create', (req, res, next) ->
    Financials.createDepositRequest(req.user, req.body.amount,
      provider: root.paymentProviders.byName(req.body.provider)
      order_id: req.body.orderId
    ).tap (financial) ->
      if req.body.status
        financial.updateStatus req.body.status
    .done (financial) ->
      res.json financial
    , next

  ###
    Router: DELETE /admin/users/:id
  ###
  router.delete '/:id', (req, res, next) ->
    unless _.isEmpty req.user.plans
      return next new Error 'already in plan'

    unless req.user.balance <= 0
      return next new Error 'balance not empty'

    req.user.remove().done ->
      res.sendStatus 204
    , next
