$ ->
	window.ErrorHandle =
		addError: (error) ->
			$('#page-alert').append "<p>#{error}</p>"

		clearError: ->
			$('#page-alert').find('button').nextAll().remove()

		showError: ->
			$('#page-alert').show()

		hideError: ->
			$('#page-alert').hide()

		flushError: (error) ->
			@clearError()
			@addError error
			@showError()
