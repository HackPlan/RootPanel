exports.rx =
  username: /^[0-9a-z_]{3,23}$/
  email: /^\w+([-+.]\w+)*@\w+([-+.]\w+)*$/
  password: /^.+$/
  domain: /(\*\.)?[A-Za-z0-9]+(\-[A-Za-z0-9]+)*(\.[A-Za-z0-9]+(\-[A-Za-z0-9]+)*)*/
  filename: /[A-Za-z0-9_\-\.]+/

exports.checkHomeFilePath = (account, path) ->
  home_dir = "/home/#{account.username}/"

  unless /^[/A-Za-z0-9_\-\.]+\/?$/.test path
    return false

  unless path.slice(0, home_dir.length) == home_dir
    return false

  unless path.length < 512
    return false

  unless path.slice(-3) != '/..'
    return false

  unless path.indexOf('/../') == -1
    return false

  return true
