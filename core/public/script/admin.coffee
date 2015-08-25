$ ->
  $('.action-generate-code').click ->
    request '/admin/generate_coupon_code',
      expired: $('.input-expired').val()
      available_times: parseInt $('.input-available_times').val()
      type: $('.input-type').val()
      meta: JSON.parse $('.input-meta').val()
      count: parseInt $('.input-count').val()
    , (coupon_codes) ->
      for coupon_code in coupon_codes
        $('.output-coupon-code').append "#{coupon_code.code}<br />"
