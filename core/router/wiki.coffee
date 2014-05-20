express = require 'express'
markdown = require('markdown').markdown
path = require 'path'
fs = require 'fs'

{renderAccount} = require './middleware'

module.exports = exports = express.Router()

exports.use (req, res) ->
  req.inject [renderAccount], ->
    url = req.url.substr 1

    unless url
      url = 'README.md'

    filename = path.resolve path.join __dirname, '../../WIKI', url
    baseDir = path.resolve path.join __dirname, '../../WIKI'

    unless filename[0..baseDir.length-1] == baseDir
      return res.json 404

    fs.readFile filename, (err, data) ->
      throw err if err
      res.render 'wiki',
        title: url
        content: markdown.toHTML data.toString()
