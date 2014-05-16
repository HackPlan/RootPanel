$ ->
  id = $('#ticketid').data 'id'
  $('#reply-btn').on 'click', (e) ->
    e.preventDefault()
    data = {
      id: id
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
        ErrorHandle.flushInfo 'error', error
  #return a promise
  changeStatus = (status) ->
    $.post '/ticket/update/', {
      id: id
      status: status
    }

  $('#close-btn').on 'click', (e) ->
    e.preventDefault()
    changeStatus 'closed'
      .done (r) ->
        ErrorHandle.flushInfo 'success', '关闭工单成功', ->
          location.reload true

  $('#reopen-btn').on 'click', (e) ->
    e.preventDefault()
    changeStatus 'open'
      .done (r) ->
        ErrorHandle.flushInfo 'success', '重开工单成功', ->
          location.reload true

