$ ->
  $('.action-leave-plan').click ->
    if confirm 'Are you sure?'
      RP.request '/billing/leave_plan',
        plan: $(@).parents('tr').data 'name'
      , ->
        location.reload()

  $('.action-join-plan').click ->
    RP.request '/billing/join_plan',
      plan: $(@).parents('tr').data 'name'
    , ->
      location.reload()
