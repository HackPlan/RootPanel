$ ->
  $.ajaxSetup
    contentType: 'application/json; charset=UTF-8'

  window.i18n_data = {}

  window.t = (name) ->
    keys = name.split '.'

    result = window.i18n_data

    for item in keys
      if result[item] == undefined
        return name
      else
        result = result[item]

    if result == undefined
      return name
    else
      return result

  window.tErr = (name) ->
    return "error_code.#{name}"

  window.request = (url, param, options, callback) ->
    unless callback
      callback = options

    jQueryMethod = $[options.method ? 'post']

    unless options.method == 'get'
      param.csrf_token = $('body').data 'csrf-token'
      param = JSON.stringify param
    else
      param = null

    jQueryMethod url, param
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert window.t "error_code.#{jqXHR.responseJSON.error}"
      else
        alert jqXHR.statusText
    .success callback

  client_version = localStorage.getItem 'locale_version'
  latest_version = $('body').data 'locale-version'

  if client_version == latest_version
    window.i18n_data = JSON.parse localStorage.getItem 'locale_cache'
  else
    $.getJSON "/account/locale/", (result) ->
      window.i18n_data = result

      localStorage.setItem 'locale_version', latest_version
      localStorage.setItem 'locale_cache', JSON.stringify result

  $('nav a').each ->
    if $(@).attr('href') == location.pathname
      $(@).parent().addClass('active')

  $('.label-language').text $.cookie('language')

  if window.location.hash == '#redirect'
    $('#site-not-exist').modal 'show'

  $('.action-logout').click (e) ->
    e.preventDefault()
    request '/account/logout', {}, ->
      location.href = '/'

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
