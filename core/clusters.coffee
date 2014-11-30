{SSHConnection, fs} = app.libs
{config} = app

exports.nodes = {}

exports.Node = Node = class Node
  info: null
  name: null

  constructor: (@info) ->
    @name = @info.name

  runCommand: (command, callback) ->

  runCommandRemote: (command, callback) ->
    connection = new SSHConnection()

    connection.on 'ready', ->
      connection.exec command, (err, stream) ->
        result = ''

        stream.on 'data', (data) ->
          result += data

        stream.on 'exit', ->
          callback err, result

    connection.connect
      host: @info.host
      username: 'rpadmin'
      privateKey: fs.readFileSync '/home/rpadmin/.ssh/id_rsa'

  writeFile: (filename, body, options, callback) ->
    tmp.file
      mode: options.mode ? 0o750
    , (err, filepath, fd) ->
      logger.error err if err

      fs.writeSync fd, content, 0, 'utf8'
      fs.closeSync fd

      child_process.exec "sudo cp #{filepath} #{filename}", (err) ->
        logger.error err if err

        fs.unlink filepath, ->
          callback()

  writeFileRemote: (filename, body, options, callback) ->

exports.initNodes = ->
  for name, info of config.nodes
    exports[name] = new Node info
