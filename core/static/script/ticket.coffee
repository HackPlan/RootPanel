$ ->
  color_mapping =
    closed: 'muted'
    open: 'primary'
    pending: 'warning'
    finish: 'success'

  Reply = Backbone.Model.extend
    idAttribute: '_id'

  Ticket = Backbone.Model.extend
    urlRoot: '/ticket/resource/'
    idAttribute: '_id'

    initialize: ->
      ReplyCollection = Backbone.Collection.extend
        url: @url() + '/replies'
        model: Reply

      @replies = new ReplyCollection()
      @replies.url = @url() + '/replies'

      @once 'change', =>
        @replies.reset @get 'replies'

  TicketCollection = Backbone.Collection.extend
    model: Ticket
    url: '/ticket/resource/'

  CreateView = Backbone.View.extend
    el: '#create-view'

    events:
      'click .action-create': 'createTicket'

    createTicket: ->
      ticket = new Ticket
        title: @$('[name=title]').val()
        content: @$('[name=content]').val()

      ticket.save().success (ticket) ->
        location.href = "/ticket/view/#{ticket._id}"

  ReplyView = Backbone.View.extend
    tagName: 'li'
    className: 'list-group-item clearfix'

    initialize: ->
      @template = _.template $('#reply-template').html()
      @model.on 'change', @render.bind @

    render: ->
      @$el.html @template @model.toJSON()
      return @

  TicketView = Backbone.View.extend
    el: 'body'

    events:
      'click .action-reply': 'replyTicket'
      'click .action-status': 'setStatus'

    id: null
    model: null

    initialize: (options) ->
      @id = options.id
      @model = new Ticket _id: @id

      @model.on 'change', @render.bind @
      @model.replies.on 'add', @appendReply.bind @
      @model.replies.on 'reset', (replies) =>
        replies.each @appendReply.bind @

      @model.fetch()

      @templateContent = _.template $('#content-template').html()
      @templateActions = _.template $('#actions-template').html()
      @templateAccountInfo = _.template $('#account-info-template').html()
      @templateMembers = _.template $('#members-template').html()

    render: ->
      view_data = @model.toJSON()
      view_data.color = color_mapping[view_data.status]
      @$('.content').html @templateContent view_data
      @$('.actions').html @templateActions view_data
      @$('.account-info').html @templateAccountInfo view_data
      @$('.members').html @templateMembers view_data
      return @

    appendReply: (reply) ->
      view = new ReplyView
        model: reply
      @$('.replies').append view.render().el

    replyTicket: ->
      @model.replies.create
        # TODO: use current account
        account: @model.get 'account'
        content: @$('[name=content]').val()
        content_html: null
        created_at: null
      @$('[name=content]').val ''

    setStatus: (e) ->
      @model.save
        status: $(e.target).data 'status'
      ,
        url: @model.url() + '/status'

  ListItemView = Backbone.View.extend
    tagName: 'tr'

    initialize: ->
      @template = _.template $('#list-item-template').html()

    render: ->
      view_data = @model.toJSON()
      view_data.color = color_mapping[view_data.status]
      @$el.html @template view_data
      return @

  ListView = Backbone.View.extend
    el: '#list-view'

    tickets: new TicketCollection()

    initialize: ->
      @tickets.on 'reset', =>
        @tickets.each (ticket) =>
          view = new ListItemView
            model: ticket
          @$('tbody').append view.render().el

      @tickets.fetch reset: true

  TicketRouter = Backbone.Router.extend
    routes:
      'ticket/create(/)': 'create'
      'ticket/list(/)': 'list'
      'ticket/view/:id(/)': 'view'

    create: -> new CreateView()
    list: -> new ListView()
    view: (id) -> new TicketView id: id

  new TicketRouter()
  Backbone.history.loadUrl location.pathname
