$ ->
  $('#create-ticket').on 'click', (e) ->
    e.preventDefault()

    $.post '/ticket/create/', JSON.stringify {
      type: $('#type').val()
      title: $('#title').val()
      content: $('#ticket-content').val()
    }
    .success ->
      location.href = '/ticket/list/'
