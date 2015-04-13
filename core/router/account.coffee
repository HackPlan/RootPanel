{Router} = require 'express'
_ = require 'lodash'

utils = require '../utils'

{i18n, Account, CouponCode} = root
{requireAuthenticate} = root.middleware

module.exports = router = new Router()

###
  Router: GET /account/register

  Response HTML.
###
router.get '/register', (req, res) ->
  res.render 'account/register'

###
  Router: GET /account/login

  Response HTML.
###
router.get '/login', (req, res) ->
  res.render 'account/login'

###
  Router: GET /account/translations/:language?

  Response {Object}.
###
router.get '/translations/:language?', (req, res) ->
  if req.params.language
    res.json i18n.packTranslations req.params.language
  else
    res.json i18n.packTranslations req

###
  Router: GET /account/preferences/edit

  Response HTML.
###
router.get '/preferences/edit', requireAuthenticate, (req, res) ->
  res.render 'account/preferences'

###
  Router: GET /account/self

  Response {Account} from {Account::pick}
###
router.get '/self', requireAuthenticate, (req, res) ->
  res.json req.account.pick 'self'

###
  Router: POST /account/register

  Request {Object}

    * `username` {String}
    * `email` {String}
    * `password` {String}

  Response {Token}.
  Set-Cookie: token.
###
router.post '/register', (req, res) ->
  Account.register(req.body).then (account) ->
    res.createToken account
  .catch (err) ->
    if err.message.match /duplicate.*username/
      res.error 'username_exist'
    else if err.message.match /Validating.*email/
      res.error 'invalid_email'
    else
      res.error err

###
  Router: POST /account/login

  Request {Object}

    * `username` {String} Username, email or account_id.
    * `password` {String}

  Response {Token}.
  Set-Cookie: token, language.
###
router.post '/login', (req, res) ->
  Account.search(req.body.username).then (account) ->
    unless account?.matchPassword req.body.password
      throw new Error 'wrong_password'

    res.createCookie 'language', account.preferences.language

    res.createToken(account).then (token) ->
      req.createSecurityLog 'login', {},
        account: account
        token: token

  .catch (err) ->
    if err.message.match /must be a/
      res.error 'wrong_password'
    else
      res.error err

###
  Router: POST /account/logout

  Set-Cookie: token.
###
router.post '/logout', requireAuthenticate, (req, res) ->
  req.token.revoke().done ->
    req.createSecurityLog('revoke_token').then ->
      res.clearCookie('token').sendStatus 204
  , res.error

###
  Router: PUT /account/password

  Request {Object}

    * `original_password` {String}
    * `password` {String}

###
router.put '/password', requireAuthenticate, (req, res) ->
  Q().done ->
    unless req.account.matchPassword req.body.original_password
      throw new Error 'wrong_password'

    unless utils.rx.password.test req.body.password
      throw new Error 'invalid_password'

    req.account.setPassword(req.body.password).then ->
      req.createSecurityLog 'update_password'
      res.sendStatus 204

  , res.error

###
  Router: PUT /email

  Request {Object}

    * `email` {String}
    * `password` {String}

###
router.post '/update_email', requireAuthenticate, (req, res) ->
  Q().done ->
    unless req.account.matchPassword req.body.password
      throw new Error 'wrong_password'

    unless utils.rx.email.test req.body.email
      throw new Error 'invalid_email'

    original_email = req.account.email

    req.account.setEmail(req.body.email).then ->
      req.createSecurityLog 'update_email',
        original_email: original_email
        current_email: req.account.email

      res.sendStatus 204

  , req.error

###
  Router: PATCH /account/preferences

  Request {Preferences}.

  Response {Preferences}.
###
router.patch '/preferences', requireAuthenticate, (req, res) ->
  req.account.updatePreferences(req.body).done (preferences) ->
    res.json preferences
  , res.error

router.use '/plans', do (router = new Router) ->
  router.param 'plan', (req, res, next, plan_name) ->
    if req.plan = root.billing.byName plan_name
      next()
    else
      res.error 'plan_not_found'

  ###
    Router: POST /account/plans/:plan/join
  ###
  router.post '/:plan/join', (req, res) ->
    if root.billing.isFrozen req.account
      return res.error 'insufficient_balance'

    unless req.plan.join_freely
      return res.error 'cant_join_plan'

    req.plan.addMember(req.account).done ->
      res.sendStatus 204
    , res.error

  ###
    Router: POST /account/plans/:plan/leave
  ###
  router.post '/:plan/leave', (req, res) ->
    req.plan.removeMember(req.account).done ->
      res.sendStatus 204
    , res.error

router.use '/coupons', do (router = new Router) ->
  ###
    Router: GET /account/coupons/:code

    Response {CouponCode}.
  ###
  router.get '/:code', (req, res) ->
    CouponCode.findByCode(req.params.code).done (coupon) ->
      if coupon
        coupon.populate(req: req).then ->
          coupon.validate(req.account).then (available) ->
            res.json _.extend coupon.pick(),
              available: available
      else
        throw new Error 'coupon_not_found'
    , res.error

  ###
    Router: POST /account/coupons/:code/apply
  ###
  router.post '/:code/apply', requireAuthenticate, (req, res) ->
    CouponCode.findByCode(req.params.code).done (coupon) ->
      if coupon
        coupon.apply(account).then ->
          res.sendStatus 204
      else
        throw new Error 'coupon_not_found'
    , res.error
