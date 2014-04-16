async = require 'async'
_ = require 'underscore'

db = require '../db'
config = require '../config'

mAccount = require '../model/account'
mTicket = require '../model/ticket'

module.exports =
  get:
    list: (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.redirect '/account/login/'

        mTicket.find
          account_id: account._id
        , {}, (tickets) ->
          res.render 'ticket/list',
            account: account
            tickets: tickets

    create: (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.redirect '/account/login/'

        res.render 'ticket/create',
          account: account
          ticketTypes: config.ticket.availableType

    view: (req, res) ->
      mAccount.authenticate req.token, (account) ->
        unless account
          return res.redirect '/account/login/'

        mTicket.findId req.body.id, (ticket) ->
          unless ticket
            return res.send 404

          unless mAccount.inGroup account, 'root'
            unless mTicket.hasMember ticket, account
              return res.send 403

          res.render 'ticket/view',
            account: account
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

          checkReplyTo = (callback) ->
            if req.body.reply_to
              mTicket.findOne
                'replys._id': req.body.reply_to
              , {}, (result) ->
                if result
                  callback null
                else
                  callback true
            else
              callback null

          checkReplyTo (err) ->
            if err
              return res.json 400, error: 'reply_not_exist'

            unless mTicket.hasMember ticket, account
              unless mAccount.inGroup account, 'root'
                return res.json 400, error: 'forbidden'

            mTicket.createReply ticket, account, req.body.reply_to, req.body.content, (reply) ->
              return res.json
                id: reply._id

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

                if mTicket.hasMember ticket, {_id: member_id}
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
