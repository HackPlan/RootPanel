child_process = require 'child_process'
{Client} = require 'ssh2'
_ = require 'underscore'
Q = require 'q'

class Node
  defaults:
    name: null
    host: '127.0.0.1'
    id_key: "#{process.env.HOME}/.ssh/id_rsa"
    username: 'rpadmin'
    master: false

  constructor: (options) ->
    _.extend @, @defaults, options

    unless @master
      @setupRemote()

  command: (command) ->
    if @master
      return Q.Promise (resolve, reject) ->
        child_process.exec command, (err, stdout, stderr) ->
          if err
            reject err
          else
            resolve
              stdout: stdout
              stderr: stderr
    else
      @exec command

  exec: (command, {args, stdin}) ->
    stdout = ''
    stderr = ''

    if @master
      return Q.Promise (resolve, reject) ->
        proc = child_process.spawn command, args

        if stdin
          proc.stdin.end stdin

        proc.on 'error', (err) ->
          reject err

        proc.stdout.on 'data', (data) ->
          stdout += data

        proc.stderr.on 'data', (data) ->
          stderr += data

        proc.on 'exit', ->
          resolve
            stdout: stdout
            stderr: stderr
    else
      @connected().then (client) ->
        return Q.Promise (resolve, reject) ->
          client.exec "#{command} #{args.join(' ')}", (err, stream) ->
            if err
              return reject err

            stream.on 'data', (data) ->
              stdout += data

            stream.stderr.on 'data', (data) ->
              stderr += data.toString()

            stream.on 'close', ->
              resolve
                stdout: stdout
                stderr: stderr

  readFile: (filename) ->
    @command("sudo cat #{filename}").then ({stdout, stderr}) ->
      if stderr
        throw new Error stderr
      else
        return stdout

  writeFile: (filename, body, {mode, owner}) ->
    @command("sudo touch #{filename}").then =>
      Q.all([
        if mode then @command("sudo chmod #{mode} #{filename}")
        if owner then @command("sudo chown #{owner}:#{owner} #{filename}")
      ]).then =>
        @exec 'sudo',
          args: ['tee', filename]
          stdin: body

  setupRemote: ->
    id_key = fs.readFileSync @id_key

    connected = Q.Promise (resolve, reject) =>
      client = new Client()

      client.connect
        host: @host
        username: @username
        privateKey: id_key

      client.on 'ready', ->
        resolve connection

      client.on 'error', (err) ->
        reject err

    @connected = ->
      return connected

module.exports = class NodeManager
  constructor: (nodes) ->
    @nodes = {}

    for name, options of nodes
      @nodes[name] = new Node _.extend options,
        name: name

  all: ->
    return _.values @nodes

  byName: (name) ->
    return @nodes[name]
