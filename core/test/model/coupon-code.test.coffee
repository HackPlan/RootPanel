describe 'model.coupon-code', ->
  {CouponCode} = root

  describe '.createCoupons', ->
    it 'should success', ->
      CouponCode.createCoupons(
        type: 'cash'
        available_times: 1
      , 5).then (codes) ->
        codes.length.should.be.equal 5
