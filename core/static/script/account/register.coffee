$ ->
  $('.action-register').click ->
    unless $('#password').val() == $('#password2').val()
      return alert t 'view.account.password_Inconsistent'

    request '/account/register/',
      username: $('#username').val()
      password: $('#password').val()
      email: $('#email').val()
    , ->
      location.href = '/panel/'
