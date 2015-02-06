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

  $('.action-register').click ->
    username = $('[name=username]').val()
    email = $('[name=email]').val()
    password = $('[name=password]').val()
    password2 = $('[name=password2]').val()

    unless password == password2
      return alert t 'view.account.password_inconsistent'

    RP.request '/account/register',
      username: username
      password: password
      email: email
    , ->
      location.href = '/panel/'
