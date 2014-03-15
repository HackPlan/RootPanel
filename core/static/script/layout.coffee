$ ->
  $('nav a').each ->
    $(@).parent().addClass('active') if $(@).attr('href') is location.pathname


  $('#logout').on 'click', (e) ->
    e.preventDefault()
    $.ajax
      method: 'post'
      url: '/account/logout/'
    .done ->
      location.href = '/'
    .fail (reply) ->
      if reply.status is 400
        error = reply.responseJSON.error
        ErrorHandle.flushError error
