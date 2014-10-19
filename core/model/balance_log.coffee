{_, ObjectId, mongoose} = app.libs

BalanceLog = mongoose.Schema
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

module.exports = mongoose.model 'BalanceLog', BalanceLog
