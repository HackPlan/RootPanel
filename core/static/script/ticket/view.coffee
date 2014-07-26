$ ->
  id = $('.row.content').data 'id'

  $('.action-reply').click ->
    $.post '/ticket/reply/', JSON.stringify
      id: id
      content: $('#reply-content').val()
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .success ->
      location.reload()

  $('.change-status').click ->
    $.post '/ticket/update/', JSON.stringify
      id: id
      status: $(@).data 'status'
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .done ->
      location.reload()
