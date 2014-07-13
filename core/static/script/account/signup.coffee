$ ->
  $('.signup-btn').on 'click', (e) ->
    e.preventDefault()
    if $('#password').val() isnt $('#password2').val()
      ErrorHandle.flushInfo 'alert', '两次密码不一致'
    else
      $.post '/account/signup/', JSON.stringify {
        username: $('#username').val()
        password: $('#password').val()
        email: $('#email').val()
      }
      .success ->
        location.href = '/'