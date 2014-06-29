exports.rx =
  username: /^[0-9a-z_]{3,23}$/
  email: /^\w+([-+.]\w+)*@\w+([-+.]\w+)*$/
  passwd: /^.+$/
  domain: /(\*\.)?[A-Za-z0-9]+(\-[A-Za-z0-9]+)*(\.[A-Za-z0-9]+(\-[A-Za-z0-9]+)*)*/
  filename: /[A-Za-z0-9_\-\.]+/
