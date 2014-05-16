$ ->
  $('.signup-btn').on 'click', (e) ->
    e.preventDefault()
    if $('#passwd').val() isnt $('#passwd2').val()
      ErrorHandle.flushInfo 'error', '两次密码不一致'
    else
      data =
        username: $('#username').val()
        passwd: $('#passwd').val()
        email: $('#email').val()
      $.ajax
        method: 'post'
        url: '/account/signup/'
        data: data
      .done (reply) ->
        location.href = '/'
      .fail (reply) ->
        if reply.status is 400
          error = reply.responseJSON.error
          ErrorHandle.flushInfo 'error', error
