$ ->
  id = $('.row.content').data 'id'

  $('.action-reply').click ->
    request "/ticket/reply/#{id}",
      content: $('.input-content').val()
    , ->
      location.reload()

  $('.action-update-status').click ->
    request "/ticket/update_status/#{id}",
      status: $(@).data 'status'
    , ->
      location.reload()
