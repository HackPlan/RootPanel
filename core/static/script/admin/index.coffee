$ ->
  #充值记录
  $ '.create-payment'
    .on 'click', (e) ->
      e.preventDefault()
      $('#account_id').html $(this).closest('tr').data 'id'
      $('#crate_payment_modal').modal 'show'

  $ '#create_payment_button'
    .on 'click', (e) ->
      e.preventDefault()
      $.post '/admin/create_payment/', JSON.stringify {
        account_id: ($ '#account_id').html()
        type: 'taobao'
        amount: ($ '#amont').val()
        order_id: ($ '#order_id').val()
      }
      .success ->
        location.reload()