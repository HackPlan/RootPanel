$ ->
  $('.action-login').click ->
    request '/account/login/',
      username: $('.input-username').val()
      password: $('.input-password').val()
    , ->
      location.href = '/panel/'

  $('#password').keypress (e) ->
    if e.keyCode == 13
      $('.action-login').click()
