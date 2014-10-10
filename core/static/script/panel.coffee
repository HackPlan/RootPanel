$ ->
  $('#service-switch button').click ->
    # TODO: refactor
    is_enable = if $(@).hasClass 'btn-success' then true else false
    $.post "/plugin/#{$(@).data('name')}/switch/", JSON.stringify
      enable: is_enable
    .fail (jqXHR) ->
      if jqXHR.responseJSON?.error
        alert jqXHR.responseJSON.error
      else
        alert jqXHR.statusText
    .success ->
      location.reload()

  $('.action-leave-plan').click ->
    if window.confirm 'Are you sure?'
      request '/billing/leave_plan/',
        plan: $(@).parents('tr').data 'name'
      , ->
        location.reload()

  $('.action-join-plan').click ->
    request '/billing/join_plan/',
      plan: $(@).parents('tr').data 'name'
    , ->
      location.reload()
