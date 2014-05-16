$ ->
  $('nav a').each ->
    $(this).parent().addClass('active') if $(this).attr('href') is location.pathname


  $('#logout').on 'click', (e) ->
    e.preventDefault()
    $.ajax {
      method: 'post'
      url: '/account/logout/'
    }
    .done ->
      location.href = '/'
    .fail (reply) ->
      if reply.status is 400
        error = reply.responseJSON.error
        ErrorHandle.flushInfo 'error', error
