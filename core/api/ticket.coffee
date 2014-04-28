async = require 'async'
_ = require 'underscore'

db = require '../db'
config = require '../config'
api = require './index'

mAccount = require '../model/account'
mTicket = require '../model/ticket'

module.exports =
  get:
    list: api.accountAuthenticateRender (req, res, account, renderer) ->
      mTicket.find
        account_id: account._id
      ,
        sort:
          updated_at: -1
      , (tickets) ->
        renderer 'ticket/list',
          tickets: tickets

    create: api.accountAuthenticateRender (req, res, account, renderer) ->
      renderer 'ticket/create',
        ticketTypes: config.ticket.availableType

    view: api.accountAuthenticateRender (req, res, account, renderer) ->
      mTicket.findId req.body.id, (ticket) ->
        unless ticket
          return res.send 404

        unless mAccount.inGroup account, 'root'
          unless mTicket.getMember ticket, account
            return res.send 403

        async.map ticket.replys, (reply, callback) ->
          mAccount.findId reply.account_id, (reply_account) ->
            reply.account = reply_account
            callback null, reply

        , (err, result) ->
          ticket.replys = result

          mAccount.findId ticket.account_id, (ticket_account) ->
            ticket.account = ticket_account

            renderer 'ticket/view',
              ticket: ticket

  post:
    create: (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        unless /^.+$/.test req.body.title
          return res.json 400, error: 'invalid_title'

        unless req.body.type in config.ticket.availableType
          return res.json 400, error: 'invalid_type'

        createTicket = (members) ->
          mTicket.createTicket account, req.body.title, req.body.content, req.body.type, members, {}, (ticket) ->
            return res.json
              id: ticket._id

        if mAccount.inGroup account, 'root'
          tasks = []

          if req.body.members
            for memberName in req.body.members
              do (memberName = _.clone(memberName)) ->
                tasks.push (callback) ->
                  mAccount.byUsernameOrEmail memberName, (member) ->
                    unless member
                      res.json 400, error: 'invalid_account', username: memberName
                      callback true

                    callback null, member

          async.parallel tasks, (err, result) ->
            if err
              return

            unless _.find(result, (item) -> item._id == account._id)
              result.push account

            createTicket result

        else
          createTicket [account]

    reply: (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        mTicket.findId req.body.id, (ticket) ->
          unless ticket
            return res.json 400, error: 'ticket_not_exist'

          unless mTicket.getMember ticket, account
            unless mAccount.inGroup account, 'root'
              return res.json 400, error: 'forbidden'

          mTicket.createReply ticket, account, req.body.content, (reply) ->
            return res.json
              id: reply._id

    list: (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        mTicket.find do ->
          selector =
            account_id: account._id

          if req.body.type?.toLowerCase() in config.ticket.availableType
            selector['type'] = req.body.type.toLowerCase()

          if req.body.status?.toLowerCase() in ['open', 'pending', 'finish', 'closed']
            selector['status'] = req.body.status.toLowerCase()

          return selector
        ,
          sort:
            updated_at: -1
          limit: req.body.limit ? 30
          skip: req.body.skip ? 0
        , (tickets) ->
          res.json _.map tickets, (item) ->
            return {
              id: item._id
              title: item.title
              type: item.type
              status: item.status
              updated_at: item.updated_at
            }

    update: (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.json 400, error: 'auth_failed'

        modifier = {}

        addToSetModifier = []
        pullModifier = []

        mTicket.findId req.body.id, (ticket) ->
          if req.body.type
            if req.body.type in config.ticket.availableType
              modifier['type'] = req.body.type
            else
              return res.json 400, error: 'invalid_type'

          if req.body.status
            if mAccount.inGroup account, 'root'
              allow_status = ['open', 'pending', 'finish', 'closed']
            else
              allow_status = ['closed']

            if req.body.status in allow_status
              if ticket.status == req.body.status
                return res.json 400, error: 'already_in_status'
              else
                modifier['status'] = ticket.status
            else
              return res.json 400, error: 'invalid_status'

          if mAccount.inGroup account, 'root'
            if req.body.attribute
              if req.body.attribute.public
                modifier['attribute.public'] = true
              else
                modifier['attribute.public'] = false

            if req.body.members
              for member_id, op of req.body.members
                member_id = db.ObjectID member_id

                if mTicket.getMember ticket, {_id: member_id}
                  unless op
                    pullModifier.push member_id
                else
                  if op
                    addToSetModifier.push member_id

          async.parallel [
            (callback) ->
              unless _.isEmpty modifier
                mTicket.update _id: ticket._id,
                  $set: modifier
                , {}, callback
              else
                callback()

            (callback) ->
              unless _.isEmpty addToSetModifier
                mTicket.update _id: ticket._id,
                  $addToSet:
                    members:
                      $each: addToSetModifier
                , {}, callback
              else
                callback()

            (callback) ->
              unless _.isEmpty pullModifier
                mTicket.update _id: ticket._id,
                  $pullAll:
                    members: pullModifier
                , {}, callback
              else
                callback()
          ], ->
            return res.json {}
