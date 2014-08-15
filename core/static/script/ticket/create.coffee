$ ->
  $('.action-create').click ->
    $.post '/ticket/create/', JSON.stringify
      type: $('#type').val()
      title: $('#title').val()
      content: $(':input[name=content]').val()
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .success (data, text_status, jqXHR) ->
      location.href = "/ticket/view/?id=#{jqXHR.responseJSON.id}"
