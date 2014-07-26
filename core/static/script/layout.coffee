$ ->
  $.ajaxSetup
    contentType: 'application/json; charset=UTF-8'

  $('nav a').each ->
    if $(@).attr('href') == location.pathname
      $(@).parent().addClass('active')

  $('#logout').click ->
    $.post '/account/logout/', {}
    .success ->
      location.reload()
