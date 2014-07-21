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
        $('#json').find('textarea').val JSON.stringify(data, null, " ")
        ($ '#nginxModal').modal 'show'


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

  $ '#nginxSave'
    .on 'click', (e) ->
      e.preventDefault()
      type = $('#nginxConfigType').find('.active a').attr('href').substr 1
      try
        $.post '/plugin/nginx/update_site/', JSON.stringify {
          action: 'create'
          type: type
          config: JSON.parse($("##{type}").find('textarea').val())
        }
        .success ->
          location.reload()
      catch e
        alert '配置文件格式不正确'

  mysql = $ '#mysql-input'
  mysql.find 'button'
    .on 'click', (e) ->
      e.preventDefault()
      $.post '/plugin/mysql/update_password/', JSON.stringify {
        password: (mysql.find 'input').val()
      }
      .success ->
        location.reload()
