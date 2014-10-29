after (done) ->
  app.models.CouponCode.remove
    _id:
      $in: created_objects.couponcodes
  , done

describe 'model/CouponCode', ->
  Account = null
  CouponCode = null

  account = null
  coupon1 = null
  coupon2 = null

  before ->
    {Account, CouponCode} = app.models
    account = namespace.accountModel.account

  describe 'createCodes', ->
    it 'should success', (done) ->
      CouponCode.createCodes
        available_times: 3
        type: 'amount'
        meta:
          category: 'test'
          amount: 4
      , 5, (err, coupons...) ->
        expect(err).to.not.exist
        coupons.should.have.length 5
        coupons[0].available_times.should.be.equal 3
        coupons[0].type.should.be.equal 'amount'
        coupons[0].meta.amount.should.be.equal 4

        [coupon1, coupon2] = coupons

        for coupon in coupons
          created_objects.couponcodes.push coupon._id

        done()

  describe 'getMessage', ->
    it 'should success', (done) ->
      req =
        t: app.i18n.getTranslator
          headers: {}
          cookies: {}

      coupon1.getMessage req, (message) ->
        message.should.be.equal '账户余额：4 CNY'
        done()

  describe 'applyCode', ->
    it 'should success', (done) ->
      coupon1.applyCode account, (err) ->
        expect(err).to.not.exist

        CouponCode.findById coupon1._id, (err, coupon1) ->
          coupon1.available_times.should.be.equal 2

          matched_account_id = _.find coupon1.apply_log, (item) ->
            return item.account_id.toString() == account.id

          matched_account_id.should.be.exist

          original_account = account
          Account.findById account._id, (err, account) ->
            (account.billing.balance - original_account.billing.balance).should.be.equal 4

          done()

  describe 'validateCode', ->
    it 'should success', (done) ->
      coupon2.validateCode {_id: new ObjectId}, (is_validated) ->
        is_validated.should.be.ok
        done()

    it 'should fail when used coupon', (done) ->
      coupon1.validateCode account, (is_validated) ->
        expect(is_validated).to.not.ok
        done()

    it 'should fail when available_times <= 0', (done) ->
      coupon2.available_times = 0
      coupon2.validateCode account, (is_validated) ->
        expect(is_validated).to.not.ok
        done()
