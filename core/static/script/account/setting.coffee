$ ->
  $('.action-update-password').click ->
    if $('.form-password :input[name=password]').val() != $('.form-password :input[name=password2]').val()
      return alert 'Two password is not equal'

    $.post '/account/update_password/', JSON.stringify
      old_password : $('.form-password :input[name=old_password]').val()
      password: $('.form-password :input[name=password]').val()
    .fail (jqXHR) ->
      alert jqXHR.responseJSON?.error ? jqXHR.statusText
    .success ->
      alert 'Success!'

  $('.action-save').click ->
    $.post '/account/update_setting/', JSON.stringify
      name: 'qq'
      value: $(':input[name=qq]').val()
    .fail (jqXHR) ->
      alert jqXHR.responseJSON?.error ? jqXHR.statusText
    .success ->
      alert 'Success!'

  $('.action-update-email').click ->
    $.post '/account/update_email/', JSON.stringify
      password: $('.form-email :input[name=password]').val()
      email: $(':input[name=email]').val()
    .fail (jqXHR) ->
      alert jqXHR.responseJSON?.error ? jqXHR.statusText
    .success ->
      alert 'Success!'
