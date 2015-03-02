$ ->
  $('.widget-ssh .action-kill').click ->
    if window.confirm 'Are you sure?'
      request '/plugin/ssh/kill',
        pid: $(@).parents('tr').data 'id'
      , =>
        $(@).parents('tr').remove()

  $('.widget-ssh .action-update-password').click ->
    request '/plugin/ssh/update_password',
      password: $('.widget-ssh .input-password').val()
    , ->
      alert 'Success'
