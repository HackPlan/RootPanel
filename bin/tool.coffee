#!/usr/bin/env coffee

_ = require 'underscore'
path = require 'path'

[plugin, name] = _.last(process.argv).split '.'
require path.join __dirname, '../plugin', plugin, 'bin', "#{name}.coffee"
