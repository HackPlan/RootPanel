{config} = app

exports.nodes = {}

exports.Node = Node = class Node
  info: null
  name: null

  constructor: (@info) ->
    @name = @info.name

  writeConfigFile: (filename, content, options, callback) ->
    unless callback
      [options, callback] = [{}, options]

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

exports.initNodes = ->
  for name, info of config.nodes
    exports[name] = new Node info
