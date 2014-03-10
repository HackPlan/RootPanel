Model = require './Model'

module.exports = class Ticket extends Model
  @create: (data) ->
    new Ticket data
