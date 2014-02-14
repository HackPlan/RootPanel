$ ->
  $('nav a').each (index) ->
    if $('nav a')[index].pathname == location.pathname
      $($('nav a')[index]).parent().addClass('active')
