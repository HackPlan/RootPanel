MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID;
_ = require 'underscore'
db = require '../db'

module.exports = class Model
  constructor: (@data) ->

  @create: ->
    throw 'this function must be overrided'

  @createModels: (docs) ->
    result = []
    for doc in docs
      result.push @create doc

    return result

  @collection: ->
    return db.mongo.collection "#{@name.toLowerCase()}s"

  @find: (selector, options, callback) ->
    arguments[arguments.length] = null

    @collection().find.apply(this, arguments).toArray (err, result) ->
      throw err if err

      callback @createModels result

  @findOne: (selector, options, callback) ->
    arguments[arguments.length] = (err, result) ->
      throw err if err
      callback @create result

    @collection().find.apply this, arguments

  @findById: (id, callback) ->
    @findOne {_id: id}, callback

  @insert: (data, options, callback = null) ->
    if _.isFunction arguments[arguments.length]
      arguments[arguments.length] = (err, result) ->
        throw err if err

        if callback
          if _.isArray data
            callback @createModels result
          else
            callback @create result[0]

    @collection().insert.apply this, arguments

  @update: (selector, documents, options, callback = null) ->
    if _.isFunction arguments[arguments.length]
      arguments[arguments.length] = (err, result) ->
        throw err if err

        if callback
          callback result

    @collection().update.apply this, arguments

  save: (options, callback = null) ->
    args = Array.prototype.slice.call arguments, 0
    args.unshift @data

    if _.isFunction args[args.length]
      args[args.length] = (err, result) ->
        throw err if err

        if callback
          callback result

    @collection().save.apply this, args

  update: (modifiers, options, callback = null) ->
    args = Array.prototype.slice.call arguments, 0
    args.unshift {_id: @data._id}

    if _.isFunction args[args.length]
      args[args.length] = (err, result) ->
        throw err if err

        if callback
          callback result

    @collection().update.apply this, args

  @remove: (selector, options, callback = null) ->
    if _.isFunction arguments[arguments.length]
      arguments[arguments.length] = (err, result) ->
        throw err if err

        if callback
          callback result

    @collection().remove.apply this, arguments

  remove: (options, callback = null) ->
    args = Array.prototype.slice.call arguments, 0
    args.unshift {_id: @data._id}

    if _.isFunction args[args.length]
      args[args.length] = (err, result) ->
        throw err if err

        if callback
          callback result

    @collection().remove.apply this, args
