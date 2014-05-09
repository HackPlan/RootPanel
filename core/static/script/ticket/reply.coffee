$ ->
  $('#reply-btn').on 'click', (e) ->
    e.preventDefault()
    data = {
      id: $('#ticketid').data 'id'
      content: $('#reply-content').val()
    }
    console.log data
    $.ajax {
      method: 'post'
      url: '/ticket/reply/'
      data: data
    }

    .done (r) ->
      location.reload true
    .fail (r) ->
      if reply.status is 400
        error = reply.responseJSON.error
        ErrorHandle.flushError error

  $('#close-btn').on 'click', (e) ->
    e.preventDefault()

    $.post '/ticket/update/', {
      id: $('#ticketid').data 'id'
      status: 'closed'
    }
    .done (r) ->
      console.log r

