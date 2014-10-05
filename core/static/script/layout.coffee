$ ->
  client_version = localStorage.getItem 'locale_version'
  latest_version = $('body').data 'locale-version'

  if client_version  == latest_version
    window.i18n_data = JSON.parse localStorage.getItem 'locale_cache'
  else
    $.getJSON "/locale/", (result) ->
      window.i18n_data = result

      localStorage.setItem 'locale_version', latest_version
      localStorage.setItem 'locale_content', JSON.stringify result

  $('nav a').each ->
    if $(@).attr('href') == location.pathname
      $(@).parent().addClass('active')

  $('.label-language').text $.cookie('language')

  if window.location.hash == '#redirect'
    $('#site-not-exist').modal 'show'

  $('#logout').click (e) ->
    e.preventDefault()
    $.post '/account/logout/', {}
    .success ->
      location.reload()

  $('.action-switch-language').click (e) ->
    e.preventDefault()

    language = $(@).data 'language'

    $.cookie 'language', language,
      expires: 365
      path: '/'

    $('.label-language').text language

    if $('body').data 'username'
      request '/account/update_preferences/',
        language: language
      , ->
        location.reload()
    else
      location.reload()
