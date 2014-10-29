after (done) ->
  app.models.CouponCode.remove
    _id:
      $in: created_objects.couponcodes
  , done

describe 'model/CouponCode', ->
  CouponCode = null

  account = null
  coupon1 = null
  coupon2 = null

  before ->
    {CouponCode} = app.models
    account = namespace.accountModel.account

  describe 'createCodes', ->
    it 'should success', (done) ->
      CouponCode.createCodes
        available_times: 3
        type: 'amount'
        meta:
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
    it 'should success'

  describe 'validateCode', ->
    it 'should success'

    it 'should fail when used coupon'
