{assertInService} = require '../../core/router/middleware'

module.exports = exports = express.Router()

exports.use assertInService 'mongodb'
