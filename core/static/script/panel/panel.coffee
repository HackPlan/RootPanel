$ ->
  $('#service-switch button').click ->
    is_enable = if $(@).hasClass 'btn-success' then true else false
    $.post "/plugin/#{$(@).data('name')}/switch/", JSON.stringify
      enable: is_enable
    .success ->
      location.reload()

  $('.btn-kill').click ->
    $.post '/plugin/ssh/kill/', JSON.stringify
      pid: $(@).parents('tr').data 'id'
    .success ->
      location.reload()

  $('#widget-mongodb button.create-database').click ->
    $.post '/plugin/mongodb/create_database', JSON.stringify
      name: $(@).parents('.input-group').find('input').val()
    .success ->
      location.reload()

  $('#widget-mongodb button.delete-database').click ->
    if window.confirm 'Are you sure?'
      $.post '/plugin/mongodb/delete_database', JSON.stringify
        name: $(@).parents('tr').data 'name'
      .success ->
        location.reload()

  $('#widget-mongodb button.update-password').click ->
    $.post '/plugin/mongodb/update_password', JSON.stringify
      password: $(@).parents('.input-group').find('input').val()
    .success ->
      location.reload()

  $('#nginx-modal .radio input').click ->
    console.log $(@).val()
    options = ['root', 'proxy', 'uwsgi']

    mapping_table =
      fastcgi: ['root']
      proxy: ['proxy']
      uwsgi: ['uwsgi']
      static: ['root']

    options_to_show = mapping_table[$(@).val()]

    for item in options
      if item in options_to_show
        $("#nginx-modal .option-#{item}").removeClass 'hide'
      else
        $("#nginx-modal .option-#{item}").addClass 'hide'

  $('#nginx-modal .modal-footer button.btn-success').click ->
    type = $('#nginx-modal ul.config-type').find('.active a').attr('href')['#nginx-type-'.length..]

    if type == 'guide'
      config = {}

    else if type == 'json'
      try
        config = JSON.parse($('#nginx-type-json textarea').val())
      catch e
        return alert 'Invalid JSON'

    else
      return alert 'Coming Soon'

    $.post '/plugin/nginx/update_site/', JSON.stringify
      action: if config.id then 'update' else 'create'
      id: config.id
      type: type
      config: config
    .success ->
      location.reload()

  # refactored above

  service = $ '#service'
  service.find 'button'
    .on 'click', (e) ->
      e.preventDefault()
      button = $ @
      prehead = if button.hasClass 'btn-success' then '' else 'un'
      $.post "/plan/#{prehead}subscribe/", JSON.stringify {
        plan: button.parents('tr').data 'type'
      }
      .success ->
        location.reload()

  ssh = $ '#ssh-input'
  ssh.find 'button'
    .on 'click', (e) ->
      e.preventDefault()
      $.post '/plugin/ssh/update_password/', JSON.stringify {
        password: ssh.find('input').val()
      }
      .success ->
        ErrorHandle.flushInfo 'success', '修改成功', ->
          location.reload()

  $ '.nginx-edit-btn'
    .on 'click', (e) ->
      e.preventDefault()
      id = ($(@).closest 'tr').data 'id'
      $.post '/plugin/nginx/site_config', JSON.stringify {
        id: id
      }
      .success (data) ->
        $('#json').find('textarea').val JSON.stringify(data, null, '    ')
        ($ '#nginx-modal').modal 'show'

  $ '.nginx-remove-btn'
    .on 'click', (e) ->
      if window.confirm('确认删除?')
        e.preventDefault()
        id = ($(@).closest 'tr').data 'id'
        $.post '/plugin/nginx/update_site', JSON.stringify {
          action: 'delete'
          id: id
          type: $('#nginxConfigType').find('.active a').attr('href').substr 1
        }
        .success ->
          location.reload()

  mysql = $ '#mysql-input'
  mysql.find 'button'
    .on 'click', (e) ->
      e.preventDefault()
      $.post '/plugin/mysql/update_password/', JSON.stringify {
        password: (mysql.find 'input').val()
      }
      .success ->
        location.reload()
