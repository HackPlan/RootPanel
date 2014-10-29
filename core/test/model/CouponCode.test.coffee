after (done) ->
  app.models.CouponCode.remove
    _id:
      $in: created_objects.couponcodes
  , done

describe 'model/CouponCode', ->
  Account = null
  CouponCode = null

  account = null

  before ->
    {Account, CouponCode} = app.models
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

        for coupon in coupons
          created_objects.couponcodes.push coupon._id

        done()
