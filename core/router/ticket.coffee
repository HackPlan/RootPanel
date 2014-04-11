async = require 'async'
clone = require 'clone'
ObjectID = require('mongodb').ObjectID

config = require '../config'

Account = require '../model/account'
Ticket = require '../model/ticket'

module.exports =
  get:
    list: (req, res) ->
      account.authenticate req.token, (account) ->
        unless account
          return res.redirect '/account/login/'

        tTicket.find
          account_id: account.id()
        , (tickets) ->
          res.render 'ticket/list',
            account: account
            tickets: tickets

    create: (req, res) ->
      account.authenticate req.token, (account) ->
        unless account
          return res.redirect '/account/login/'

        res.render 'ticket/create',
          account: account
          ticketTypes: config.ticket.availableType

  post:
    create: (req, res) ->
      account.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        data = req.body

        unless /^.+$/.test data.title
          return res.json 400, error: 'invalid_title'

        unless data.type in config.ticket.availableType
          return res.json 400, error: 'invalid_type'

        createTicket = (members) ->
          tTicket.createTicket account, data.title, data.content, data.type, members, {}, (ticket) ->
            return res.json
              id: ticket.id()

        if account.inGroup 'root'
          tasks = []

          if data.members
            for memberName in data.members
              do (memberName = clone(memberName)) ->
                tasks.push (callback) ->
                  account.byUsernameOrEmail memberName, (member) ->
                    unless member
                      res.json 400, error: 'invalid_account', username: memberName
                      callback true

                    callback null, member

            async.parallel tasks, (err, result) ->
              if err
                return

              unless _.find(result, (item) -> item.id() == account.id())
                result.push account

              createTicket result

        else
          createTicket [account]

    reply: (req, res) ->
      account.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        data = req.body

        tTicket.findById data.id, (ticket) ->
          checkReplyTo = (callback) ->
            if data.reply_to
              tTicket.findOne
                'replys._id': data.reply_to
              , (result) ->
                if result
                  callback null
                else
                  callback true
            else
              callback null

          checkReplyTo (err) ->
            if err
              return res.json 400, error: 'reply_not_exist'

            unless ticket.hasMember account
              unless account.inGroup 'root'
                return res.json 400, error: 'forbidden'

            ticket.createReply account, data.reply_to, data.content, (reply) ->
              return res.json
                id: reply._id

    update: (req, res) ->
      account.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        data = req.body
        modifier = {}

        addToSetModifier = []
        pullModifier = []

        tTicket.findById data.id, (ticket) ->
          if data.type
            if data.type in config.ticket.availableType
              modifier['type'] = data.type
            else
              return res.json 400, error: 'invalid_type'

          if data.status
            if account.inGroup 'root'
              allow_status = ['open', 'pending', 'finish', 'closed']
            else
              allow_status = ['closed']

            if data.status in allow_status
              if ticket.data.status == data.status
                return res.json 400, error: 'already_in_status'
              else
                modifier['status'] = ticket.data.status
            else
              return res.json 400, error: 'invalid_status'

          if account.inGroup 'root'
            if data.attribute
              unless data.attribute.public == undefined
                modifier['attribute.public'] = false
              else
                modifier['attribute.public'] = true

            if data.members
              for member_id, op of data.members
                member_id = new ObjectID member_id

                if ticket.hasMemberId member_id
                  unless op
                    pullModifier.push member_id
                else
                  if op
                    addToSetModifier.push member_id

          async.parallel [
            (callback) ->
              unless _.isEmpty modifier
                ticket.update
                  $set: modifier
                , callback
              else
                callback()

            (callback) ->
              unless _.isEmpty addToSetModifier
                ticket.update
                  $addToSet:
                    members:
                      $each: addToSetModifier
                , callback
              else
                callback()

            (callback) ->
              unless _.isEmpty pullModifier
                ticket.update
                  $pullAll:
                    members: pullModifier
                , callback
              else
                callback()
          ], ->
            return res.json {}




                
        
