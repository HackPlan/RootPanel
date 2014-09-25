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

    if result == undefined or typeof result == 'object'
      return name
    else
      return result

  window.tErr = (name) ->
    return "error_code.#{name}"

  clientVersion = localStorage.getItem 'localeVersion'
  currentVersion = "#{($ 'body').data 'locale'}"

  if clientVersion  == currentVersion
    window.i18n_data = JSON.parse(localStorage.getItem 'localeContent')
  else
    $.getJSON "/locale/#{$.cookie('language')}", (data) ->
      window.i18n_data = data
      localStorage.setItem 'localeVersion', currentVersion
      localStorage.setItem 'localeContent', JSON.stringify data
