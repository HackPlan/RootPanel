$ ->
  $('#widget-shadowsocks .action-reset-password').click ->
    if window.confirm 'Are you sure?'
      $.post '/plugin/shadowsocks/reset_password/', {}
      .fail (jqXHR) ->
        if jqXHR.responseJSON?.error
          alert jqXHR.responseJSON.error
        else
          alert jqXHR.statusText
      .success ->
        location.reload()
