$ ->
  {agent} = root

  $('nav a').each ->
    if $(@).attr('href') == location.pathname
      $(@).parent().addClass 'active'

  $('.action-logout').click (event) ->
    event.preventDefault()
    agent.post('/account/logout').then ->
      location.href = '/'

  #

  _.extend window.RP,
    i18n_data: {}

    initLocale: ->
      client_version = localStorage.getItem 'locale_version'
      latest_version = $('body').data 'locale-version'

      if client_version == latest_version
        RP.i18n_data = JSON.parse localStorage.getItem 'locale_cache'
      else
        $.getJSON "/account/locale/", (result) ->
          RP.i18n_data = result
          localStorage.setItem 'locale_version', latest_version
          localStorage.setItem 'locale_cache', JSON.stringify result

    t: (name) ->
      keys = name.split '.'

      result = RP.i18n_data

      for item in keys
        if result[item] == undefined
          return name
        else
          result = result[item]

      if result == undefined
        return name
      else
        return result

    tErr: (name) ->
      return RP.t "error_code.#{name}"

  $('.label-language').text $.cookie('language')

  if location.hash == '#redirect'
    $('#site-not-exist').modal 'show'

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
