$ ->
  $('.action-create-payment').click ->
    $('#account_id').html $(@).parents('tr').data 'id'
    $('#create-payment-modal').modal 'show'

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
