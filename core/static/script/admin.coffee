$ ->
  $('#tab-account-list .action-confirm-payment').click ->
    $('.confirm-payment-modal .input-account-id').html $(@).parents('tr').data 'id'
    $('.confirm-payment-modal').modal 'show'

  $('.action-delete-account').click (e) ->
    e.preventDefault()
    $.post '/admin/delete_account/', JSON.stringify
      account_id: $(@).parents('tr').data 'id'
    .success ->
      location.reload()

  $('.action-disable-site').click (e) ->
    e.preventDefault()
    $.post '/admin/update_site/', JSON.stringify
      site_id: $(@).parents('tr').data 'id'
      is_enable: false
    .success ->
      location.reload()

  $('.action-enable-site').click (e) ->
    e.preventDefault()
    $.post '/admin/update_site/', JSON.stringify
      site_id: $(@).parents('tr').data 'id'
      is_enable: true
    .success ->
      location.reload()

  $('.confirm-payment-modal .action-confirm-payment').click ->
    request '/admin/confirm_payment/',
      account_id: $('.input-account-id').test()
      type: 'taobao'
      amount: $('input-amount').val()
      order_id: $('input-order-id').val()
    , ->
      location.reload()

  $('.action-generate-code').click ->
    request '/admin/generate_coupon_code/',
      expired: $('.input-expired').val()
      available_times: parseInt $('.input-available_times').val()
      type: $('.input-type').val()
      meta: JSON.parse $('.input-meta').val()
      count: parseInt $('.input-count').val()
    , (coupon_codes) ->
      for coupon_code in coupon_codes
        $('.output-coupon-code').append "#{coupon_code.code}<br />"
