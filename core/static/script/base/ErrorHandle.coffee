$ ->
	window.ErrorHandle =
		addInfo: (type, info) ->
			$("#page-#{type}").append "<p>#{info}</p>"

		clearInfo: (type) ->
			$("#page-#{type}").empty()

		showInfo: (type, callback) ->
			$("#page-#{type}").show 1000, if callback? then callback or null


		hideInfo: (type) ->
			$("#page-#{type}").hide()

		flushInfo: (type, error, callback = null) ->
			@clearInfo type
			@addInfo type, error
			@showInfo type, callback


