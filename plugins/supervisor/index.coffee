module.exports = class Supervisor
  constructor: (@injector) ->
    @injector.component 'program', new SupervisorComponent @

    @injector.widget 'panel',
      required:
        createable: 'supervisor.program'
      generator: (account, component) ->
        root.views.render __dirname + '/view/widget'

  getSupervisor: (node) ->
    if node
      return new SupervisorManager root.servers.byName node
    else
      return new SupervisorManager root.servers.master()

class SupervisorComponent
  constructor: ({@getSupervisor}) ->

  preSave: ({options}) ->
    (new Program options).validate()

  initialize: (component) ->
    (new Program component.options).populate(component).then ({configuration}) =>
      @getSupervisor(node).writeConfig configuration, [component.options]

  update: (component) ->
    (new Program component.options).populate(component).then ({configuration}) =>
      @getSupervisor(node).writeConfig configuration, [component.options]

  destroy: (component) ->
    (new Program component.options).populate(component).then ({configuration}) =>
      @getSupervisor(node).removeConfig configuration

  actions: [
    control:
      handler: ({node, account: {username}, options: {name}}, {action}) =>
        @getSupervisor(node).controlProgram
          user: username
          name: name
        , action
  ]

Program = mabolo.model 'Program',
  command:
    type: String
    required: true
    validator: (command) ->
      unless /^.*$/.test command
        throw new Error 'invalid_command'

  autostart:
    type: Boolean
    required: true
    default: true

  autorestart:
    type: String
    enum: ['true', 'false', 'unexpected']

  directory:
    type: String
    validator: (directory) ->
      unless /^.*$/.test directory
        throw new Error 'invalid_directory'

Program::populate = ({account, name}) ->
  return Q _.extend @,
    user: account.username
    name: "#{account.username}-#{name}"
    configuration: "user.#{account.username}.#{name}"
