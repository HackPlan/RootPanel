MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID;
_ = require 'underscore'
db = require '../db'

# @param callback(args, callback)
mongoOverloadHelper = (that, commend, args, callback) ->
  args = _.toArray args
  originalCallback = _.find args, _.isFunction
  collection = that.collection()

  args[args.length - 1] = (err, result) ->
    callback err, result, originalCallback

  commend.apply collection, args

module.exports = class Model
  constructor: (@data) ->

  @create: ->
    throw 'this function must be overrided'

  @createModels: (docs) ->
    result = []

    for doc in docs
      result.push @create doc

    return result

  id: ->
    return @data._id

  @collection: ->
    return db.mongo.collection "#{@name.toLowerCase()}s"

  @find: (selector, options, callback) ->
    args = _.toArray arguments
    callback = _.find args, _.isFunction
    collection = @collection()

    args[args.length - 1] = null

    collection.find.apply(collection, args).toArray (err, result) =>
      throw err if err
      callback @createModels result

  @findOne: (selector, options, callback) ->
    mongoOverloadHelper @, @collection().findOne, arguments, (err, result, callback) =>
      throw err if err

      if result
        callback @create result
      else
        callback null

  @findById: (id, callback) ->
    @findOne {_id: id}, callback

  @insert: (data, options, callback = null) ->
    mongoOverloadHelper @, @collection().insert, arguments, (err, result, callback) =>
      throw err if err

      if callback
        if _.isArray data
          callback @createModels result
        else
          callback @create result[0]

  @update: (selector, documents, options, callback = null) ->
    mongoOverloadHelper @, @collection().update, arguments, (err, result, callback) =>
      throw err if err

      if callback
        callback result

  save: (options, callback = null) ->
    mongoOverloadHelper @constructor, @constructor.collection().save, arguments, (err, result, callback) =>
      throw err if err

      if callback
        callback result

  update: (modifiers, options, callback = null) ->
    args = _.toArray arguments

    callback = _.find args, _.isFunction
    collection = @constructor.collection()

    args.unshift {_id: @data._id}

    args[args.length - 1] = (err, result) ->
      throw err if err

      if callback
        callback result

    collection.update.apply collection, args

  @remove: (selector, options, callback = null) ->
    mongoOverloadHelper @, @collection().remove, arguments, (err, result, callback) =>
      throw err if err

      if callback
        callback result

  remove: (options, callback = null) ->
    args = _.toArray arguments

    callback = _.find args, _.isFunction
    collection = @constructor.collection()

    args.unshift {_id: @data._id}

    args[args.length - 1] = (err, result) ->
      throw err if err

      if callback
        callback result

    collection.remove.apply collection, args
