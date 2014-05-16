$ ->
  id = $('#ticketid').data 'id'
  #return a promise
  changeStatus = (status) ->
    $.post '/ticket/update/', {
      id: id
      status: status
    }
  checkContent = ->
    if $('#reply-content').val() is ''
      console.log 's'
      ErrorHandle.flushInfo 'alert', '回复不能为空'
      return false
    true
  $('#reply-btn').on 'click', (e) ->
    e.preventDefault()
    return unless checkContent()
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
        ErrorHandle.flushInfo 'alert', error


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

