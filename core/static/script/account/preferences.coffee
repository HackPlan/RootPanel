$ ->
  $('.action-save').click ->
    request '/account/update_preferences',
      qq: $('.form-setting .input-qq').val()
    , ->
      alert t 'common.success'

  $('.action-use').click ->
    code = $('.form-coupon .input-coupon_code').val()

    request '/coupon/info',
      code: code
    , (result) ->
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
