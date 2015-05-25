$ ->
  Component = Backbone.Model.extend
    idAttribute: '_id'

  CompontentCollection = Backbone.Collection.extend
    model: Component
    url: '/components/'

  ListItemView = Backbone.View.extend
    tagName: 'tr'

    initialize: ->
      @template = RP.tmpl '#list-item-template'

    render: ->
      @$el.html @template @model.toJSON()
      return @

  ListView = Backbone.View.extend
    el: '#list-view'

    components: new CompontentCollection()

    initialize: ->
      @components.on 'reset', =>
        @components.each (component) =>
          view = new ListItemView
            model: component
          @$('.table-component tbody').append view.render().el

      @components.fetch reset: true

  new ListView()
