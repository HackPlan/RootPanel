$ ->
  $('nav a').each ->
    $(@).parent().addClass('active') if $(@).attr('href') is location.pathname

