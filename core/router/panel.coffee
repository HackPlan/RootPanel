{express, async, _} = app.libs
{requireAuthenticate} = app.middleware
{Account, Financials} = app.models
{billing, config} = app

module.exports = exports = express.Router()

exports.use requireAuthenticate

exports.post '/join_plan', (req, res) ->
  {plan} = req.body

  unless billing.plans[plan]
    return res.error 'invalid_plan'

  if req.account.inPlan plan
    return res.error 'already_in_plan'

  if req.account.balance <= when_balance_below
    return res.error 'insufficient_balance'

  billing.joinPlan req.account, plan, (err) ->
    console.log err
    if err
      res.error err
    else
      res.status(204).json {}

exports.post '/leave_plan', (req, res) ->
  {plan} = req.body

  unless req.account.inPlan plan
    return res.error 'not_in_plan'

  billing.leavePlan req.account, plan, (err) ->
    if err
      res.error err
    else
      res.status(204).json {}

exports.get '/financials', (req, res) ->
  LIMIT = 10

  async.parallel
    payment_methods: (callback) ->
      async.map app.applyHooks('billing.payment_methods'), (hook, callback) ->
        hook.widgetGenerator req, (html) ->
          callback null, html
      , callback

    deposit_log: (callback) ->
      Financials.find
        account_id: req.account._id
        type: 'deposit'
      , null,
        sort:
          created_at: -1
        limit: LIMIT
      , (err, deposit_logs) ->
        async.map deposit_logs, (deposit_log, callback) ->
          deposit_log = deposit_log.toObject()

          matched_hook = _.find app.applyHooks('billing.payment_methods'), (hook) ->
            return hook.type == deposit_log.payload.type

          unless matched_hook
            return callback null, deposit_log

          matched_hook.detailsMessage req, deposit_log, (payment_details) ->
            deposit_log.payment_details = payment_details
            callback null, deposit_log

        , callback

    billing_log: (callback) ->
      Financials.find
        account_id: req.account._id
        type: 'billing'
      , null,
        sort:
          created_at: -1
        limit: LIMIT
      , callback

  , (err, result) ->
    res.render 'panel/financials', result

exports.get '/components', (req, res) ->
  templates = _.compact _.map req.account.availableComponentsTemplates(), (template_name) ->
    return app.components[template_name]

  res.render 'panel/components',
    templates: templates

exports.get '/', (req, res) ->
  billing.triggerBilling req.account, (err, account) ->
    return res.error err if err

    async.auto
      widgets_html: (callback) ->
        app.applyHooks('view.panel.widgets', account,
          execute: 'generator'
          req: req
        ) callback

    , (err, result) ->
      res.render 'panel', _.extend result,
        account: account
        plans: _.filter billing.plans, (plan) ->
          return plan.join_freely
