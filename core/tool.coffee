Tool =
	firstCapital : (str) ->
		return str.replace /\b\w+\b/g,(word) ->
			return word.substring(0,1).toUpperCase() + word.substring 1

	typeIsArray : Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

	nullFuc : ->
module.exports = Tool