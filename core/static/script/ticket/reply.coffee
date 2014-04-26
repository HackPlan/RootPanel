$ ->
  $('#reply').on 'click', (e) ->
    e.preventDefault()
    data = {
      id: $('#ticketid').data 'id'
      content: $('#reply-content').val()
    }

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