{mabolo} = app
{ObjectID} = mabolo

Financials = mabolo.model 'Financials',
  account_id:
    required: true
    type: ObjectID
    ref: 'Account'

  type:
    required: true
    type: String
    enum: ['deposit', 'billing']

  amount:
    required: true
    type: Number

  created_at:
    type: Date
    default: -> new Date()

  payload:
    type: Object

Financials.createLog = (account, type, amount, payload) ->
  Q().then ->
    unless isFinite amount
      throw new Error 'invalid_amount'

    @create
      account_id: account._id
      type: type
      amount: amount
      payload: payload
