$ ->
  $('.action-login').click ->
    RP.request '/account/login',
      username: $('[name=username]').val()
      password: $('[name=password]').val()
    , ->
      location.href = '/panel/'

  $('[name=password]').keypress (e) ->
    if e.keyCode == 13
      $('.action-login').click()
