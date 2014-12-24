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
      async.map pluggable.selectHook('billing.payment_methods'), (hook, callback) ->
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

          matched_hook = _.find pluggable.selectHook('billing.payment_methods'), (hook) ->
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

exports.get '/', (req, res) ->
  view_data =
    account: req.account
    plans: []
    widgets_html: []

  for name, info of Plan.plans
    view_data.plans.push _.extend _.clone(info),
      is_enabled: req.account.inPlan name

  async.map pluggable.selectHook('view.panel.widgets'), (hook, callback) ->
    hook.generator req, (html) ->
      callback null, html

  , (err, widgets_html) ->
    view_data.widgets_html = widgets_html

    res.render 'panel', view_data
