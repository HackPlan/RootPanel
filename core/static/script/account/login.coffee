$ ->
  $('#login-btn').on 'click', (e)->
    e.preventDefault()
    $.post '/account/login/', JSON.stringify {
      username : $('#username').val()
      password : $('#password').val()
    }
    .success ->
      location.href '/'
