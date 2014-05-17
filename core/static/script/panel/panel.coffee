$ ->
  service = $ '#service'
  service.find 'button'
          .on 'click', (e) ->
            e.preventDefault()
            button = $ @
            prehead = if button.hasClass 'btn-success' then '' else 'un'
            $.post "/plan/#{prehead}subscribe/", {
              plan: button.parent().data 'type'
            }
            .success ->
              location.reload()
            .fail (reply) ->
              if reply.status is 400
                error = reply.responseJSON.error
                ErrorHandle.flushInfo 'alert', error

  ssh = $ '#ssh-input'
  ssh.find 'button'
      .on 'click', (e) ->
        e.preventDefault()
        $.post '/plugin/ssh/update_passwd/', {
          passwd: ssh.find('input').val()
        }
        .success ->
          ErrorHandle.flushInfo 'success', '修改成功', ->
            location.reload t_resources
        .fail (reply) ->
          if reply.status is 400
            error = reply.responseJSON.error
            ErrorHandle.flushInfo 'alert', error
