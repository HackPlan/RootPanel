{config} = root

module.exports = class ViewHelpers
  constructor: (@req, @res) ->
    @t = @req.getTranslator()

  title: (title_i18n_id) ->
    return "#{@t title_i18n_id} | #{@t config.web.name}"
