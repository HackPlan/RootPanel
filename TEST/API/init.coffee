async = require 'async'

db = require '../../core/db'

module.exports = (callback) ->
  cAccount = db.collection 'accounts'
  cTicket = db.collection 'tickets'

  async.parallel [
    (callback) ->
      cAccount.remove
        username: $in: ['test', 'test_main']
      , callback

    (callback) ->
      cAccount.remove
        email: 'test@jysperm.me'
      , callback

    (callback) ->
      cAccount.insert
        _id: db.ObjectID '533b0cb894f6c673123e33a3'

        username: 'test_main'
        passwd: '9de9bb1f01888f4cf6c32cd02c6ad2b15804b292947552324ae8f7d52e12714c'
        passwd_salt: '9499537d1f65ae43e7ac4d1c2901bb7647ac735b5b9b6c9eea945d8453c3636f'
        email: 'test_main@jysperm.me'
        singup_at: new Date()

        group: ['root']
        setting: {}
        attribute: {}

        tokens: [
          {
            token: 'token'
            available: true
            created_at: new Date()
            updated_at: new Date()

            attribute: {}
          },
          {
            token: 'need_be_remove'
            available: true
            created_at: new Date()
            updated_at: new Date()

            attribute: {}
          }
        ]
      , callback

    (callback) ->
      cTicket.remove
        account_id: db.ObjectID '533b0cb894f6c673123e33a3'
      , callback

    (callback) ->
      cTicket.insert
        _id: db.ObjectID '533b0cb894f6c673123e33a4'
        account_id: db.ObjectID '533b0cb894f6c673123e33a3'
        created_at: new Date()
        updated_at: new Date()
        title: 'Ticket Title'
        content: 'Ticket Content(Markdown)'
        content_html: 'Ticket Conetnt(HTML)'
        type: 'linux'
        status: 'open'
        members: [
          db.ObjectID '533b0cb894f6c673123e33a3'
        ]
        attribute: {}
        replys: []
      , callback

  ], ->
    callback()

unless module.parent
  db.connect ->
    module.exports ->
      process.exit()
