module.exports =
  get:
    '/': (req, res) ->
      res.redirect '/panel/'
