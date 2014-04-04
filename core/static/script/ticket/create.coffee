$ ->
  $('#create-ticket').on 'click', (e) ->
    e.preventDefault()
    data = {
      type: $('#type').val()
      title: $('#title').val()
      content: $('#content').val()
    }

    $.ajax {
      method: 'post'
      url: '/ticket/create/'
      data: data
    }
    .done (reply) ->
      console.log reply
    .fail (reply) ->
      if reply.status is 400
        error = reply.responseJSON.error
        ErrorHandle.flushError error