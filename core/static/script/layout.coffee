$ ->
  $.ajaxSetup {
    contentType: 'application/json; charset=UTF-8'
  }

  $('nav a').each ->
    if $(@).attr('href') == location.pathname
      $(@).parent().addClass('active')

  $('#logout').on 'click', (e) ->
    e.preventDefault()
    $.post '/account/logout/', {}
    .success ->
      location.href = '/'
