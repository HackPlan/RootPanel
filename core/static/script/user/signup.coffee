$ ->
  username = $('#username').val()
  email = $('#email').val()
  passwd = $('#passwd').val()
  passwd2 = $('#passwd2').val()


  checkAndRequest = (tag, obj) ->
    form = $(tag)
    data = {}
    error = false
    $('#page-alert').show()

    for k, v of obj
      item = form.find "##{k}"

      formGroup = item.closest '.form-group'
      method = v['check']
      result = switch typeof method
        when "object" then method.test item.val()
        when "function" then method()
        when "string"
          method is ''
        else
          throw "form check >obj >#{k} error"

      if result
        formGroup.addClass 'has-success'
        data[k] = item.val()
      else
        formGroup.addClass 'has-error'
        $('#page-alert').append "<p>#{v['error']}</p>"
        error = true
        
    if not error
      $('#page-alert').hide()

      $.ajax
        url: '/user/signup'
        method: 'post'
        data: data
        success: (reply) ->
          console.log reply


  $('.signup-form').find('button').on 'click', (e) ->
    e.preventDefault()
    checkAndRequest '.signup-form',
      username:
        check: /^[0-9a-z_]+$/
        error: '用户名必须以数字或小写字母开头'
      email:
        check: /^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$/
        error: '邮箱格式不正确'
      passwd:
        check: ->
          $('#passwd').val() is $('#passwd2').val()
        error: '两次密码不一致'
