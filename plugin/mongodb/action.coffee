module.exports =
  update_passwd:
    mode: 'passwd'
    callback: ->

  create_db:
    mode: 'text'
    callback: ->

  delete_db:
    mode: 'select'
    source: ->
    callback: ->

  reset_db_permission:
    mode: 'select'
    source: ->
    callback: ->
