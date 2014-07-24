$ ->

  $(document).ajaxError (e, reply) ->
    if reply.status is 400
      error = reply.responseJSON.error
      ErrorHandle.flushInfo 'alert', error
  $.ajaxSetup {
    contentType: 'application/json; charset=UTF-8'
  }

  $('nav a').each ->
    $(this).parent().addClass('active') if $(this).attr('href') is location.pathname


  $('#logout').on 'click', (e) ->
    e.preventDefault()
    $.post '/account/logout/', {}
    .success ->
      location.href = '/'