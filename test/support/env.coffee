process.env.NODE_ENV = 'test'

require("chai").should()

if process.env.COV_TEST == 'true'
  require('coffee-coverage').register
    path: 'relative'
    basePath: "#{__dirname}/../.."
    exclude: ['test', 'node_modules', '.git', 'sample', 'core/static']
    initAll: true
