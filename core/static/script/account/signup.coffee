$ ->
  $('.signup-btn').on 'click', (e) ->
    e.preventDefault()
    if $('#passwd').val() isnt $('#passwd2').val()
      ErrorHandle.flushInfo 'alert', '两次密码不一致'
    else
      $.post '/account/signup/', JSON.stringify {
        username: $('#username').val()
        passwd: $('#passwd').val()
        email: $('#email').val()
      }
      .success ->
        location.href = '/'