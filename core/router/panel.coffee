{express, async, _} = app.libs
{requireAuthenticate} = app.middleware
{Account, Financials} = app.models
{pluggable, billing, config} = app
{Plan} = app.interfaces

module.exports = exports = express.Router()

exports.use requireAuthenticate

exports.get '/financials', (req, res) ->
  LIMIT = 10

  async.parallel
    payment_methods: (callback) ->
      async.map pluggable.applyHooks('billing.payment_methods'), (hook, callback) ->
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

          matched_hook = _.find pluggable.applyHooks('billing.payment_methods'), (hook) ->
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
  templates = _.map req.account.getAvailableComponentsTemplates(), (template_name) ->
    return pluggable.components[template_name]

  res.render 'panel/components',
    templates: templates

exports.get '/', (req, res) ->
  billing.triggerBilling req.account, (err, account) ->
    return res.error err if err

    async.parallel
      widgets_html: (callback) ->
        pluggable.applyHooks('view.panel.widgets', account, execute: 'generator') callback

    , (err, result) ->
      res.render 'panel', _.extend result,
        account: account
        plans: _.filter billing.plans, (plan) ->
          return plan.join_freely
