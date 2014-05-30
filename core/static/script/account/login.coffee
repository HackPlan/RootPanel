$ ->
  $('#login-btn').on 'click', (e)->
    e.preventDefault()
    $.post '/account/login/', JSON.stringify {
      username : $('#username').val()
      passwd : $('#passwd').val()
    }
    .success ->
      location.href '/'
