$ ->
  id = $('.row.content').data 'id'

  $('.action-reply').click ->
    request '/ticket/reply/',
      id: id
      content: $('.input-content').val()
    , (result) ->
      location.reload()

  $('.action-update-status').click ->
    request '/ticket/update_status/',
      id: id
      status: $(@).data 'status'
    , (result) ->
      location.reload()
