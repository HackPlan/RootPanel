module.exports = class ShadowsocksManager
  user: 'nobody'

  constructor: (@server, {@available_ciphers}) ->
    @supervisor = root.plugins.byName('supervisor').getSupervisor @server.node
    @cache = root.cache

  initialize: ->
    Q.all @available_ciphers.map (cipher) =>
      @supervisor.writeConfig "shadowsocks-#{cipher}", program cipher

  writeConfig: (cipher, users) ->
    configure = generateConfigure cipher, users

    @server.writeFile("/etc/shadowsocks/#{cipher}.json", configure, mode: 640).then =>
      @supervisor.updateProgram program cipher
    .then =>
      @supervisor.programControl program cipher

  addMonitor: ({port}) ->
    @server.command("sudo iptables -I OUTPUT -p tcp --sport #{port}").then =>
      @saveIptablesRules()

  removeMonitor: ({port}) ->
    @server.command("sudo iptables -D OUTPUT -p tcp --sport #{port}").then =>
      @saveIptablesRules()

  monitoring: ->
    Q.all([
      @cache.getJSON 'shadowsocks:last_traffic'
      @incomingTraffic()
    ]).then ([last_traffic_records, traffic_records]) ->
      current_traffic_records = []

      Q.all traffic_records.map ({port, bytes}) ->
        {bytes: last_bytes} = _.findWhere last_traffic_records,
          port: port

        current_traffic_records.push
          port: port
          bytes: bytes

        if bytes < last_bytes
          return {
            port: port
            bytes: bytes
          }
        else
          return {
            port: port
            bytes: bytes - last_bytes
          }

    .tap =>
      @cache.setex 'shadowsocks:last_traffic', 3600, JSON.stringify current_traffic_records

  incomingTraffic: ->
    CHAIN_OUTPUT = 'Chain OUTPUT'
    records = []

    @server.command('sudo iptables -n -v -L -t filter -x --line-numbers').then ({stdout}) ->
      for line in _.compact stdout.split '\n'
        is_chain_output = false

        if is_chain_output
          try
            [num, pkts, bytes, prot, opt, in_, out, source, destination, proto, port] = line.split /\s+/

            unless num == 'num'
              port = port.match(/spt:(\d+)/)[1]

              records.push
                num: parseInt num
                pkts: parseInt pkts
                bytes: parseInt bytes
                port: parseInt port

          catch e
            continue

        if line[ ... CHAIN_OUTPUT.length] == CHAIN_OUTPUT
          is_chain_output = true

      return records

  saveIptablesRules: ->
    @server.command 'sudo iptables-save | sudo tee /etc/iptables.rules'

program = (cipher) ->
  return {
    name: "shadowsocks-#{cipher}"
    user: @user
    command: "ssserver -c /etc/shadowsocks/#{cipher}.json"
    autostart: true
    autorestart: true
  }

generateConfigure = (cipher, users) ->
  configure =
    server: '0.0.0.0'
    local_port: 1080
    port_password: {}
    timeout: 60
    method: cipher
    workers: 2

  for {port, password} in users
    configure.port_password[port] = password

  return JSON.stringify configure
