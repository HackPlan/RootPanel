$ ->
  {agent} = root

  $('[name=password]').keypress (e) ->
    if e.keyCode == 13
      $('.action-login').click()

  $('.action-login').click ->
    agent.post '/account/login',
      username: $('[name=username]').val()
      password: $('[name=password]').val()
    .then ->
      location.href = '/panel/'

  $('.action-register').click ->
    username = $('[name=username]').val()
    email = $('[name=email]').val()
    password = $('[name=password]').val()
    password2 = $('[name=password2]').val()

    unless password == password2
      return alert t 'view.account.password_inconsistent'

    agent.post '/account/register',
      username: username
      password: password
      email: email
    .then ->
      location.href = '/panel/'

  #

  $('.action-save').click ->
    request '/account/update_preferences',
      qq: $('[name=qq]').val()
    , ->
      alert t 'common.success'

  $('.action-use').click ->
    code = $('[name=coupon_code]').val()

    request "/coupon/info?code=#{code}", {}, {method: 'get'}, (result) ->
      if window.confirm result.message
        request '/coupon/apply',
          code: code
        , ->
          alert t 'common.success'

  $('.action-update-password').click ->
    password = $('.form-password .input-password').val()
    password2 = $('.form-password .input-password2').val()

    if password != password2
      return alert t 'view.account.password_inconsistent'

    request '/account/update_password/',
      original_password: $('.form-password .input-original_password').val()
      password: password
    , ->
      alert t 'common.success'

  $('.action-update-email').click ->
    request '/account/update_email/',
      password: $('.form-email .input-password').val()
      email: $('.form-email .input-email').val()
    , ->
      alert t 'common.success'
