$ ->
  $('#login-btn').on 'click', (e)->
    e.preventDefault()
    data =
      username : $('#username').val()
      passwd : $('#passwd').val()

    $.ajax
      method: 'post'
      url: '/user/login/'
      data: data
    .done (reply) ->
      console.log reply
      location.href = '/'
    .fail (reply) ->
      if reply.status is 400
        error = reply.responseJSON.error
        pageErrorHandle.clearError()
        pageErrorHandle.addError error
        pageErrorHandle.showError()
