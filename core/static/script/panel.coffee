$ ->
  $('#service-switch button').click ->
    is_enable = if $(@).hasClass 'btn-success' then true else false
    $.post "/plugin/#{$(@).data('name')}/switch/", JSON.stringify
      enable: is_enable
    .success ->
      location.reload()

  $('.btn-kill').click ->
    if window.confirm 'Are you sure?'
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

  syncToJSON = ->
    username = $('.nav.navbar-nav.navbar-right li:first a').text()

    try
      config = JSON.parse($('#nginx-type-json textarea').val())
    catch e
      config = {}

    config['listen'] ?= 80

    config['is_enable'] = $('.option-is-enable input').prop('checked')
    config['server_name'] = $('.option-server-name input').val().split ' '

    switch $('.option-type :radio:checked').val()
      when 'fastcgi'
        config['root'] = $('.option-root input').val() or $('.option-root input').prop('placeholder')
        config['index'] ['index.php', 'index.html']
        config['location'] ?= {}
        config['location']['/'] =
          try_files: ['$uri', '$uri/', '/index.php?$args']
        config['location']['~ \\.php$'] =
          fastcgi_pass: "unix:///home/#{username}/phpfpm.sock"
          include: 'fastcgi_params'

      when 'proxy'
        config['location'] ?= {}
        config['location']['/'] =
          proxy_pass: $('.option-proxy input').val() or $('.option-proxy input').prop('placeholder')
          proxy_set_header:
            Host: '$host'

      when 'uwsgi'
        config['location'] ?= {}
        config['location']['/'] =
          uwsgi_pass: $('.option-uwsgi input').val() or $('.option-uwsgi input').prop('placeholder')
          include: 'uwsgi_params'

      when 'static'
        config['index'] ?= 'index.html'
        config['root'] = $('.option-root input').val() or $('.option-root input').prop('placeholder')

    $('#nginx-type-json textarea').val JSON.stringify(config, null, '    ')
    return config

  syncToGuide = ->
    $('.json-error').parent().addClass 'hide'

    try
      config = JSON.parse($('#nginx-type-json textarea').val())
    catch e
      return

    $('.option-is-enable input').prop 'checked', config['is_enable']
    $('.option-server-name input').val config['server_name']?.join ' '
    $('.option-root input').val config['root']

    type = do ->
      unless config['location']['/']
        return 'static'

      if config['location']['/']['proxy_pass']
        return 'proxy'

      if config['location']['/']['uwsgi_pass']
        return 'uwsgi'

      if config['location']['/']?['try_files']
        for item in config['location']['/']['try_files']
          if item.match(/\.php/)
            return 'factcgi'

      return 'static'

    $("#nginx-modal :radio[value=#{type}]").click()

    switch type
      when 'proxy'
        $('.option-proxy input').val config['location']['/']['proxy_pass']
      when 'uwsgi'
        $('.option-uwsgi input').val config['location']['/']['uwsgi_pass']
      when 'static', 'fastcgi'
        $('.option-root input').val config['root']

  $('#nginx-type-json textarea').on 'change keyup paste', ->
    try
      JSON.parse($('#nginx-type-json textarea').val())
      $('.json-error').parent().addClass 'hide'
    catch err
      console.log err
      $('.json-error').text err.toString()
      $('.json-error').parent().removeClass 'hide'

  $('#nginx-modal ul li a').click ->
    switch $(@).prop('href').match(/.*#nginx-type-(.*)/)[1]
      when 'json'
        syncToJSON()
      when 'guide'
        syncToGuide()

  $('#nginx-modal .radio input').click ->
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
    type = $('#nginx-modal ul.config-type').find('.active a').prop('href').match(/.*#nginx-type-(.*)/)[1]

    if type == 'guide'
      config = syncToJSON()

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
      type: 'json'
      config: config
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText

    .done ->
      location.reload()

  $('#widget-nginx .btn-danger.glyphicon-remove-sign').click ->
    if window.confirm 'Are you sure?'
      $.post '/plugin/nginx/update_site', JSON.stringify
        action: 'delete'
        id: $(@).parents('tr').data 'id'
      .success ->
        location.reload()

  $('#widget-nginx th .btn-success').click ->
    $('#nginx-modal .site-id').text ''

  $('#widget-nginx button.btn-info').click ->
    $.post '/plugin/nginx/site_config', JSON.stringify
      id: $(@).parents('tr').data 'id'
    .success (data) ->
      $('#nginx-type-json textarea').val JSON.stringify(data, null, '    ')
      syncToGuide()
      $('#nginx-modal .site-id').text data.id
      $('#nginx-modal').modal 'show'

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

  mysql = $ '#mysql-input'
  mysql.find 'button'
    .on 'click', (e) ->
      e.preventDefault()
      $.post '/plugin/mysql/update_password/', JSON.stringify {
        password: (mysql.find 'input').val()
      }
      .success ->
        location.reload()
