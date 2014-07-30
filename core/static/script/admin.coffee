$ ->
  $('.action-create-payment').click ->
    $('#account_id').html $(@).parents('tr').data 'id'
    $('#create-payment-modal').modal 'show'

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
