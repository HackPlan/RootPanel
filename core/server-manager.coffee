child_process = require 'child_process'
{Client} = require 'ssh2'
fs = require 'q-io/fs'
_ = require 'underscore'
Q = require 'q'

###
  Class: Server node, managed by {ServerManager}.
###
class ServerNode
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

  ###
    Public: Run shell command on this server.

    * `command` {String}

    Return {Promise} resolve with `{stdout, stderr}`.
  ###
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

  ###
    Public: Execute program on this server.

    * `command` {String}
    * `options` {Object}

      * `params` {Array} of {String}
      * `stdin` {String}

    Return {Promise} resolve with `{stdout, stderr}`.
  ###
  exec: (command, {params, stdin}) ->
    stdout = ''
    stderr = ''

    if @master
      return Q.Promise (resolve, reject) ->
        proc = child_process.spawn command, params

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
          client.exec "#{command} #{params.join(' ')}", (err, stream) ->
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

  ###
    Public: Read file from this server.

    * `filename` {String}

    Return {Promise}.
  ###
  readFile: (filename) ->
    @command("sudo cat #{filename}").then ({stdout, stderr}) ->
      if stderr
        throw new Error stderr
      else
        return stdout

  ###
    Public: Write file to this server.

    * `filename` {String}
    * `body` {String}
    * `options` {Object}

      * `mode` (optional) {String} e.g. `644`
      * `owner` (optional) {String}

    Return {Promise}.
  ###
  writeFile: (filename, body, {mode, owner}) ->
    @command("sudo touch #{filename}").then =>
      Q.all([
        if mode then @command("sudo chmod #{mode.toString()} #{filename}")
        if owner then @command("sudo chown #{owner}:#{owner} #{filename}")
      ]).then =>
        @exec 'sudo',
          params: ['tee', filename]
          stdin: body

  setupRemote: ->
    connected = Q.Promise (resolve, reject) =>
      fs.read(@id_key).then (id_key) =>
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

###
  Manager: Server node manager,
  You can access a global instance via `root.servers`.
###
module.exports = class ServerManager
  constructor: (@config) ->
    @servers = {}

    for name, options of @config
      @servers[name] = new ServerNode _.extend options,
        name: name

  ###
    Public: Get all server nodes.

    Return {Array} of {ServerNode}.
  ###
  all: ->
    return _.values @servers

  ###
    Public: Get specified server.

    * `name` {String}

    Return {ServerNode}.
  ###
  byName: (name) ->
    return @servers[name]

  master: ->
    return _.findWhere @servers,
      master: true
