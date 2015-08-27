before ->
  {Account, Component} = root

  Q.all [
    Account.remove()
    Component.remove()
  ]
