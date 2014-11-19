$ ->
  $('.action-create').click ->
    request '/ticket/create',
      title: $('.input-title').val()
      content: $('.input-content').val()
    , (result) ->
      location.href = "/ticket/view/#{result.id}"
