$ ->
  $('#widget-ssh .btn-kill').click ->
    if window.confirm 'Are you sure?'
      $.post '/plugin/ssh/kill/', JSON.stringify
        pid: $(@).parents('tr').data 'id'
      .fail (jqXHR) ->
        if jqXHR.responseJSON?.error
          alert jqXHR.responseJSON.error
        else
          alert jqXHR.statusText
      .success ->
        location.reload()

  $('#widget-ssh .update-password button').click ->
    $.post '/plugin/ssh/update_password/', JSON.stringify
      password: $('#widget-ssh .update-password input').val()
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .success ->
      location.reload()
