{_, express} = app.libs
{requireAuthenticate} = app.middleware
{Account, SecurityLog, CouponCode} = app.models
{pluggable, config, utils, logger} = app

module.exports = exports = express.Router()

exports.get '/coupon_info', requireAuthenticate, (req, res) ->
  CouponCode.getCode req.body.code, (coupon_code) ->
    unless coupon_code
      return res.error 'code_not_exist'

    CouponCode.restrictCode req.account, coupon_code, (err) ->
      if err
        return res.error 'code_not_available'

      CouponCode.codeMessage coupon_code, (message) ->
        res.json
          message: message

exports.post '/apply_coupon', requireAuthenticate, (req, res) ->
  CouponCode.getCode req.body.code, (coupon_code) ->
    if coupon_code.expired and Date.now() > coupon_code.expired.getTime()
      return res.error 'code_expired'

    unless coupon_code.available_times > 0
      return res.error 'code_not_available'

    apply_log = _.find coupon_code.apply_log, (i) ->
      return i.account_id.toString() == req.account._id.toString()

    if apply_log
      return res.error 'already_used'

    CouponCode.applyCode req.account, coupon_code, ->
      res.json {}
