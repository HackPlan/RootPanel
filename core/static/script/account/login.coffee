$ ->
  $('#login-btn').on 'click', (e)->
    e.preventDefault()
    data =
      username : $('#username').val()
      passwd : $('#passwd').val()

    $.ajax
      method: 'post'
      url: '/account/login/'
      data: data
    .done (reply) ->
      location.href = '/'
    .fail (reply) ->
      if reply.status is 400
        error = reply.responseJSON.error
        ErrorHandle.flushInfo 'error', error
