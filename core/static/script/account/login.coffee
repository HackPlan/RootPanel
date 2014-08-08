$ ->
  $('.action-login').click ->
    $.post '/account/login/', JSON.stringify
      username : $('#username').val()
      password : $('#password').val()
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .success ->
      location.href = '/panel/'

  $('#password').keypress (e) ->
    if e.keyCode == 13
      $('.action-login').click()
