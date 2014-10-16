process.env.NODE_ENV = 'test'

require("chai").should()

global.application = require '../../../app'
