$ ->
  $('.signup-form').find('button').on 'click', (e) ->
    e.preventDefault()
    $('.signup-form').checkAndRequest '/user/signup',(reply)->
    	console.log reply
    ,
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
