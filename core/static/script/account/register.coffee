$ ->
  $('.action-register').click ->
    username = $('.input-username').val()
    password = $('.input-password').val()
    password2 = $('.input-password2').val()
    email = $('.input-email').val()

    unless password == password2
      return alert t 'view.account.password_inconsistent'

    request '/account/register',
      username: username
      password: password
      email: email
    , ->
      location.href = '/panel/'
