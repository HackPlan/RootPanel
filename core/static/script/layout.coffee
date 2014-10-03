$ ->
  $.ajaxSetup
    contentType: 'application/json; charset=UTF-8'

  window.request = (url, param, options, callback) ->
    unless callback
      callback = options

    jQueryMethod = $[options.method ? 'post']

    jQueryMethod url, JSON.stringify param
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert window.t "error_code.#{jqXHR.responseJSON.error}"
      else
        alert jqXHR.statusText
    .success callback

  $('nav a').each ->
    if $(@).attr('href') == location.pathname
      $(@).parent().addClass('active')

  $('body > header nav ul.navbar-right > li.dropdown').append $.cookie('language')

  if window.location.hash == '#redirect'
    $('#site-not-exist').modal 'show'

  $('#logout').click (e) ->
    e.preventDefault()
    $.post '/account/logout/', {}
    .success ->
      location.reload()

  window.i18n_data = {}

  window.t = (name) ->
    keys = name.split '.'

    result = window.i18n_data

    for item in keys
      unless result[item] == undefined
        result = result[item]

    if result == undefined
      return name
    else
      return result

  window.tErr = (name) ->
    return "error_code.#{name}"

  client_version = localStorage.getItem 'locale_version'
  latest_version = $('body').data 'locale-version'

  if client_version  == latest_version
    window.i18n_data = JSON.parse localStorage.getItem 'locale_cache'
  else
    $.getJSON "/locale/", (result) ->
      window.i18n_data = result

      localStorage.setItem 'locale_version', latest_version
      localStorage.setItem 'locale_content', JSON.stringify result
