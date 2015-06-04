{markdown} = require 'markdown'
Mabolo = require 'mabolo'
_ = require 'lodash'
Q = require 'q'

{ObjectID} = Mabolo

###
  Model: Ticket reply,
  Embedded as a array at `replies` of {Ticket}.
###
Reply = Mabolo.model 'Reply',
  # Public: Related account
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  # Public: Markdown content of reply
  content:
    required: true
    type: String

  # Public: HTML content of reply
  content_html:
    required: true
    type: String

  created_at:
    required: true
    type: Date
    default: -> new Date()

###
  Model: Ticket.
###
module.exports = Ticket = Mabolo.model 'Ticket',
  # Public: Related account
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  # Public: Title of ticket
  title:
    required: true
    type: String

  # Public: Status of ticket
  status:
    required: true
    type: String
    enum: ['opening', 'pending', 'finished', 'closed']

  # Public: Markdown content of ticket
  content:
    required: true
    type: String

  # Public: HTML content of ticket
  content_html:
    required: true
    type: String

  # Public: Members of ticket
  members_id: [ObjectID]

  # Public: Replies of ticket
  replies: [Reply]

  created_at:
    required: true
    type: Date
    default: -> new Date()

  updated_at:
    required: true
    type: Date
    default: -> new Date()

Account = require './account'

###
  Public: Create ticket.

  * `account` {Account}
  * `ticket` {Object}

    * `title` {String}
    * `content` {String}
    * `status` (optional) {String}

  Return {Promise} resolve with created {Ticket}.
###
Ticket.createTicket = (account, {title, content, status}) ->
  unless title?.trim()
    return Q.reject new Error 'empty_title'

  if account.isAdmin()
    status ?= 'open'
  else
    status = 'pending'

  @create
    account_id: account._id
    title: title
    status: status
    content: content
    content_html: markdown.toHTML content
    members_id: [account._id]

###
  Public: Find tickets available to specified account.

  * `account` {Account}

  Return {Promise} resolve with array of {Ticket}.
###
Ticket.getTickets = (account) ->
  @find
    $or: [
      account_id: account._id
    ,
      members_id: account._id
    ]
  ,
    sort:
      updated_at: -1

###
  Public: Find tickets available to specified account group by status.

  * `account` {Account}

  Return {Promise} resolve with `{status: [{Ticket}]}`.
###
Ticket.getTicketsGroupByStatus = (account, options) ->
  getTicketsOfStatus = (status) =>
    @find
      $or: [
        account_id: account._id
      ,
        members_id: account._id
      ]
      status: status
    ,
      sort:
        updated_at: -1
      limit: options?[status]?.limit

  Q.all([
    getTicketsOfStatus 'pending'
    getTicketsOfStatus 'opening'
    getTicketsOfStatus 'finished'
    getTicketsOfStatus 'closed'
  ]).then ([pending, opening, finished, closed]) ->
    return {
      pending: pending
      opening: opening
      finished: finished
      closed: closed
    }

###
  Public: Create reply for this ticket.

  * `account` {Account}
  * `reply` {Object}

    * `content` {String}
    * `status` (optional) {String}

  Return {Promise} resolve with create reply.
###
Ticket::createReply = (account, {content, status}) ->
  if @status == 'closed'
    return Q.reject new Error 'already_closed'

  unless content?.trim()
    return Q.reject new Error 'empty_content'

  if account.isAdmin()
    status ?= 'open'
  else
    status = 'pending'

  reply = new Reply
    _id: new ObjectID()
    account_id: account._id
    content: content
    content_html: markdown.toHTML content

  @update
    $push:
      replies: reply
    $set:
      status: status
      updated_at: new Date()
  .thenResolve reply

###
  Public: Set status by specified account.

  * `account` {Account}
  * `status` {String}

  Return {Promise}.
###
Ticket::setStatusByAccount = (account, status) ->
  if account.isAdmin()
    unless status in ['open', 'pending', 'finish', 'closed']
      return Q.reject new Error 'invalid_status'
  else
    unless status in ['closed']
      return Q.reject new Error 'invalid_status'

  @setStatus status

###
  Public: Set status.

  * `status` {String}

  Return {Promise}.
###
Ticket::setStatus = (status) ->
  unless status in ['open', 'pending', 'finish', 'closed']
    return Q.reject new Error 'invalid_status'

  @update
    $set:
      status: status
      updated_at: new Date()

###
  Public: Check has specified member.

  * `account` {Account}

  Return {Boolean}.
###
Ticket::hasMember = (account) ->
  return _.some @members_id, (member_id) ->
    return member_id.equals account._id

###
  Public: Populate refs accounts.

  This function will populate following fields:

  * `account`: {Account} from `account_id`.
  * `members`: {Account} from `members_id`.
  * `replies.$.account`: {Account} from `replies.$.account_id`.

  Return {Promise}.
###
Ticket::populateAccounts = ->
  if @account
    return Q @

  Account.find
    _id:
      $in: [
        @account_id, @members_id..., _.pluck(@replies, 'account_id')...
      ]

  .then (accounts) =>
    @account = _.find accounts, ({_id}) =>
      return @account_id.equals _id

    @members = _.filter accounts, ({_id}) =>
      return @hasMember _id

    @replies.forEach (reply) ->
      reply.account = _.find accounts, ({_id}) ->
        return reply.account_id.equals _id

    return @
