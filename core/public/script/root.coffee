methods = ['get', 'post', 'delete', 'put', 'patch', 'head', 'options']

window.root =
  agent: {}

  t: (name) ->
    return name

methods.forEach (method) ->
  root.agent[method] = (url, data, options = {}) ->
    unless method == 'get'
      data = JSON.stringify data
      options.contentType = 'application/json; charset=UTF-8'

    _.extend options,
      url: url
      data: data
      type: method.toUpperCase()

    $.ajax(options).fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert root.t jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
