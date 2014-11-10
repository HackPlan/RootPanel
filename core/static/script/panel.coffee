$ ->
  $('.action-leave-plan').click ->
    if window.confirm 'Are you sure?'
      request '/billing/leave_plan',
        plan: $(@).parents('tr').data 'name'
      , ->
        location.reload()

  $('.action-join-plan').click ->
    request '/billing/join_plan',
      plan: $(@).parents('tr').data 'name'
    , ->
      location.reload()
