$ ->
  $('#tab-account-list .action-confirm-payment').click ->
    $('.confirm-payment-modal .input-account-id').html $(@).parents('tr').data 'id'
    $('.confirm-payment-modal').modal 'show'

  $('.action-delete-account').click (e) ->
    e.preventDefault()
    if window.confirm 'Are you sure?'
      request '/admin/delete_account',
        account_id: $(@).parents('tr').data 'id'
      , ->
        location.reload()

  $('.confirm-payment-modal .action-confirm-payment').click ->
    request '/admin/confirm_payment',
      account_id: $('.input-account-id').text()
      type: 'taobao'
      amount: parseFloat $('.input-amount').val()
      order_id: $('.input-order-id').val()
    , ->
      location.reload()

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
