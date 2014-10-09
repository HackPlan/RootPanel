$ ->
  $.ajaxSetup
    contentType: 'application/json; charset=UTF-8'

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

  window.request = (url, param, options, callback) ->
    unless callback
      callback = options

    jQueryMethod = $[options.method ? 'post']

    param.csrf_token = $('body').data 'csrf-token'

    jQueryMethod url, JSON.stringify param
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert window.t "error_code.#{jqXHR.responseJSON.error}"
      else
        alert jqXHR.statusText
    .success callback

