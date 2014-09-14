$ ->
  $('.action-signup').click ->
    unless $('#password').val() == $('#password2').val()
      return alert '两次密码不一致'

    $.post '/account/signup/', JSON.stringify
      username: $('#username').val()
      password: $('#password').val()
      email: $('#email').val()
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .success ->
      location.href = '/panel/'
