$ ->
  $('.widget-shadowsocks .action-reset-password').click ->
    if window.confirm 'Are you sure?'
      request '/plugin/shadowsocks/reset_password/', {}, ->
        location.reload()

  $('.widget-shadowsocks .action-switch-method').click ->
    request '/plugin/shadowsocks/switch_method/',
      method: $('.widget-shadowsocks .input-method').val()
    , ->
      alert 'Success'
