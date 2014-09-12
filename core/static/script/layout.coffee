$ ->
  $.ajaxSetup
    contentType: 'application/json; charset=UTF-8'

  $('nav a').each ->
    if $(@).attr('href') == location.pathname
      $(@).parent().addClass('active')

  if window.location.hash == '#redirect'
    $('#site-not-exist').modal 'show'

  $('#logout').click (e) ->
    e.preventDefault()
    $.post '/account/logout/', {}
    .success ->
      location.reload()

  window.i18n = {}

  $.getJSON "/locale/#{$.cookie('language')}.json", (data) ->
    window.i18n = data
