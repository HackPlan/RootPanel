$ ->
  $('#widget-mysql .update-password button').click ->
    $.post '/plugin/mysql/update_password/', JSON.stringify
      password: $('#widget-mysql .update-password input').val()
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .success ->
      location.reload()
