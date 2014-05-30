$ ->
  $(document).ajaxError (e, reply) ->
    console.log reply
    if reply.status is 400
      error = reply.responseJSON.error
      ErrorHandle.flushInfo 'alert', error
  $.ajaxSetup {
    contentType: 'application/json; charset=UTF-8'
  }

  service = $ '#service'
  service.find 'button'
          .on 'click', (e) ->
            e.preventDefault()
            button = $ @
            prehead = if button.hasClass 'btn-success' then '' else 'un'
            $.post "/plan/#{prehead}subscribe/", JSON.stringify {
              plan: button.parent().data 'type'
            }
            .success ->
              location.reload()

  ssh = $ '#ssh-input'
  ssh.find 'button'
      .on 'click', (e) ->
        e.preventDefault()
        $.post '/plugin/ssh/update_passwd/', JSON.stringify {
          passwd: ssh.find('input').val()
        }
        .success ->
          ErrorHandle.flushInfo 'success', '修改成功', ->
            location.reload t_resources

  fpm = $ '#php-fpm'
  fpm.on 'click', (e) ->
    e.preventDefault()
    enable = if fpm.hasClass 'btn-success' then true else false
    $.post '/plugin/phpfpm/switch/', JSON.stringify {enable: enable}
    .success ->
      location.reload()

  $ '#nginxSave'
    .on 'click', (e) ->
      e.preventDefault()
      $.post '/plugin/nginx/update_site/', {
        action: 'create'
        type: $('#nginxConfigType').find('.active a').attr('href').substr 1
        config: JSON.parse $('#nginxModal').find('textarea').val()
      }
      .success ->
        location.reload()
