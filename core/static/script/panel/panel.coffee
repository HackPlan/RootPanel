$ ->
  service = $ '#service'
  service.find 'button'
    .on 'click', (e) ->
      e.preventDefault()
      button = $ @
      prehead = if button.hasClass 'btn-success' then '' else 'un'
      $.post "/plan/#{prehead}subscribe/", JSON.stringify {
        plan: button.parent().parent().data 'type'
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

  fpm = $ '#php-fpm'
  fpm.on 'click', (e) ->
    e.preventDefault()
    enable = if fpm.hasClass 'btn-success' then true else false
    $.post '/plugin/phpfpm/switch/', JSON.stringify {enable: enable}
    .success ->
      location.reload()
  #nginx
  $ '.nginx-edit-btn'
    .on 'click', (e) ->
      e.preventDefault()
      id = ($(@).closest 'tr').data 'id'
      $.post '/plugin/nginx/site_config', JSON.stringify {
        id: id
      }
      .success (data) ->
        $('#json').find('textarea').val JSON.stringify(data, null. " ")
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
      $.post '/plugin/nginx/update_site/', JSON.stringify {
        action: 'create'
        type: $('#nginxConfigType').find('.active a').attr('href').substr 1
        config: JSON.parse $('#nginxModal').find('textarea').val()
      }
      .success ->
        location.reload()

  #mysql插件
  mysql = $ '#mysql-input'
  mysql.find 'button'
    .on 'click', (e) ->
      e.preventDefault()
      $.post '/plugin/mysql/update_password/', JSON.stringify {
        password: (mysql.find 'input').val()
      }
      .success ->
        location.reload()
