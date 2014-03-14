$ ->
	window.pageErrorHandle =
		addError: (error) ->
			$('#page-alert').append "<p>#{error}</p>"

		clearError: ->
			$('#page-alert').find('button').nextAll().remove()

		showError: ->
			$('#page-alert').show()

		hideError: ->
			$('#page-alert').hide()

	$.fn.checkAndRequest = (url, opts, callback, errorHandle) ->
		defaults = {}

		opts = $.extend defaults, opts

		form = $(@)
		error = false
		data = {}
		$('#page-alert').show().find('button').nextAll().remove()

		for k, v of opts
			item = form.find "##{k}"
			formGroup = item.closest '.form-group'
			method = v['check']
			result = switch typeof method
				when "object" then method.test item.val()
				when "function" then method()
				when "string"
					rt = switch method
						when 'required'
							item.val() isnt ''
						when ''
							true
						else
							false
				else
					false
			if result
				formGroup.addClass 'has-success'
				data[k] = item.val()
			else
				formGroup.addClass 'has-error'
				$('#page-alert').append "<p>#{v['error']}</p>"
				error = true

		if not error
			$('#page-alert').hide()

			$.ajax
				url: url
				method: 'post'
				data: data
				success: callback
				error: errorHandle
