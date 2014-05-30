$ ->
  id = $('#ticketid').data 'id'
  #return a promise
  changeStatus = (status) ->
    $.post '/ticket/update/', JSON.stringify {
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

    $.post '/ticket/reply/', JSON.stringify {
      id: id
      content: $('#reply-content').val()
    }
    .success ->
      location.reload true

  $('.change-status').on 'click', (e) ->
    e.preventDefault()
    status = $(this).data 'status'
    changeStatus status
      .done ->
        ErrorHandle.flushInfo 'success', "#{status}工单成功", ->
        location.reload true


