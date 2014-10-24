{pluggable} = app
{_, ObjectId, mongoose} = app.libs

Financials = mongoose.Schema
  account_id:
    required: true
    type: ObjectId
    ref: 'Account'

  type:
    required: true
    type: String
    enum: ['deposit']

  amount:
    required: true
    type: Number

  created_at:
    type: Date
    default: Date.now

  payload:
    type: Object
    default: {}

_.extend app.models,
  Financials: mongoose.model 'Financials', Financials
