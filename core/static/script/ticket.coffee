$ ->
  Ticket = Backbone.Model.extend
    url: '/ticket/resource/'
    idAttribute: '_id'

  CreateView = Backbone.View.extend
    el: '#create-view'

    events:
      'click .action-create': 'createTicket'

    createTicket: ->
      ticket = new Ticket
        title: @$('.input-title').val()
        content: @$('.input-content').val()

      ticket.save().success (ticket) ->
        location.href = "/ticket/view/#{ticket.id}"

  TicketView = Backbone.View.extend
    el: '#ticket-view'

    events:
      'click .action-reply': 'replyTicket'
      'click .action-update-status': 'updateStatus'

    replyTicket: ->
      request "/ticket/reply/#{id}",
        content: $('.input-content').val()
      , ->
        location.reload()

    updateStatus: ->
      request "/ticket/update_status/#{id}",
        status: $(@).data 'status'
      , ->
        location.reload()

  ListItemView = Backbone.View.extend()

  ListView = Backbone.View.extend()

  TicketRouter = Backbone.Router.extend
    routes:
      'ticket/create(/)': 'create'
      'ticket/list(/)': 'list'
      'ticket/view/:id(/)': 'view'

    create: ->
      new CreateView()

    list: ->

    view: (id) ->

  new TicketRouter()
  Backbone.history.loadUrl location.pathname
