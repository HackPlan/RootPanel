$ ->
  $('#widget-mongodb button.create-database').click ->
    $.post '/plugin/mongodb/create_database', JSON.stringify
      name: $(@).parents('.input-group').find('input').val()
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .success ->
      location.reload()

  $('#widget-mongodb button.delete-database').click ->
    if window.confirm 'Are you sure?'
      $.post '/plugin/mongodb/delete_database', JSON.stringify
        name: $(@).parents('tr').data 'name'
      .fail (jqXHR) ->
        if jqXHR.responseJSON?.error
          alert jqXHR.responseJSON.error
        else
          alert jqXHR.statusText
      .success ->
        location.reload()

  $('#widget-mongodb button.update-password').click ->
    $.post '/plugin/mongodb/update_password', JSON.stringify
      password: $(@).parents('.input-group').find('input').val()
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .success ->
      location.reload()
