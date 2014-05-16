$ ->
  service = $ '#service'
  service.find 'button'
          .on 'click', (e) ->
            e.preventDefault()
            button = $ @
            prehead = if button.hasClass 'btn-success' then '' else 'un'
            $.post "/plan/#{prehead}subscribe/", {
              plan: button.parent().data 'type'
            }