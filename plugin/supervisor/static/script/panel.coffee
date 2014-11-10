$ ->
  diglog = $('#supervisor-dialog')

  $('.widget-supervisor .action-control').click ->
    request "/plugin/supervisor/program_control/#{$(@).parents('tr').data('id')}",
      action: $(@).data 'action'
    , ->
      location.reload()

  $('.widget-supervisor .action-create').click ->
    diglog.find('.label-program-id').val ''
    diglog.find('.input-name').val ''
    diglog.find('.input-command').val ''
    diglog.find('.input-directory').val ''
    diglog.find('.input-autostart').prop 'checked', true
    diglog.find(".input-autorestart :radio[value=unexpected]").click()

  diglog.find('.action-submit').click ->
    if diglog.find('.label-program-id').text()
      url = "/plugin/supervisor/update_program/#{$(@).parents('tr').data('id')}"
    else
      url= '/plugin/supervisor/create_program'

    request url,
      name: diglog.find('.input-name').val()
      command: diglog.find('.input-command').val()
      directory: diglog.find('.input-directory').val()
      autostart: diglog.find('.input-autostart').prop('checked')
      autorestart: diglog.find('.input-autorestart :radio:checked').val()
    , ->
      location.reload()

  $('.widget-supervisor .action-edit').click ->
    request "/plugin/supervisor/program_config/#{$(@).parents('tr').data('id')}", {}, (program) ->
      diglog.find('.label-program-id').val program.id
      diglog.find('.input-name').val program.name
      diglog.find('.input-command').val program.command
      diglog.find('.input-directory').val program.directory
      diglog.find('.input-autostart').prop 'checked', program.autostart
      diglog.find(".input-autorestart :radio[value=#{program.autorestart}]").click()

      $('#nginx-modal').modal 'show'

  $('.widget-supervisor .action-remove').click ->
    if window.confirm 'Are you sure?'
      request "/plugin/supervisor/remove_program/#{$(@).parents('tr').data('id')}", {}, ->
        location.reload()
