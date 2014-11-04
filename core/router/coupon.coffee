{_, express} = app.libs
{requireAuthenticate} = app.middleware
{CouponCode} = app.models
{config, utils, logger} = app

module.exports = exports = express.Router()

exports.use requireAuthenticate

exports.get '/info', (req, res) ->
  CouponCode.findOne
    code: req.query.code
  , (err, coupon) ->
    unless coupon
      return res.error 'code_not_exist'

    coupon.validateCode req.account, (is_available) ->
      unless is_available
        return res.error 'code_not_available'

      coupon.getMessage req, (message) ->
        res.json
          message: message

exports.post '/apply', (req, res) ->
  CouponCode.findOne
    code: req.body.code
  , (err, coupon) ->
    unless coupon
      return res.error 'code_not_exist'

    if coupon.expired and Date.now() > coupon.expired.getTime()
      return res.error 'code_expired'

    if coupon.available_times and coupon.available_times < 0
      return res.error 'code_not_available'

    coupon.validateCode req.account, (is_available) ->
      unless is_available
        return res.error 'code_not_available'

      coupon.applyCode req.account, ->
        res.json {}
