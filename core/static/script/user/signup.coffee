$ ->
  $('.signup-form').find('button').on 'click', (e) ->
    e.preventDefault()
    $('.signup-form').checkAndRequest '/user/signup/',
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
    , (reply) ->
    	location.href = '/'
    , (reply) ->
    	if reply.status is 400
    		error = reply.responseJSON.error
    		pageErrorHandle.addError error
    		pageErrorHandle.clearError()
    		pageErrorHandle.showError()
