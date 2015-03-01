{mabolo} = app
{_, ObjectID
, mongoose} = app.libs
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
