$ ->
  $('.action-update-password').click ->
    if $(':input[name=password]').val() != $(':input[name=password2]').val()
      return alert 'Two password is not equal'

    $.post '/account/update_password/', JSON.stringify
      old_password : $(':input[name=old_password]').val()
      password : $(':input[name=password]').val()
    .fail (jqXHR) ->
      alert jqXHR.responseJSON?.error ? jqXHR.statusText
    .success ->
      alert 'Success!'
