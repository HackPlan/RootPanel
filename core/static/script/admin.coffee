$ ->
  $('.action-create-payment').click ->
    $('#account_id').html $(@).parents('tr').data 'id'
    $('#create-payment-modal').modal 'show'

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

  $('#create-payment-modal .action-create-payment').click ->
    $.post '/admin/create_payment/', JSON.stringify
      account_id: $('#account_id').html()
      type: 'taobao'
      amount: $('#amont').val()
      order_id: $('#order_id').val()
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .success ->
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
