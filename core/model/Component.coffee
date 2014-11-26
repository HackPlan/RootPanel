{_, ObjectId, mongoose} = app.libs

Component = mongoose.Schema
  component_type:
    required: true
    type: String
    enum: []

  name:
    required: true
    type: String

  account_id:
    required: true
    type: ObjectId
    ref: 'Account'

  coworkers: [
    account_id:
      required: true
      type: ObjectId
      ref: 'Account'

    role:
      required: true
      type: String
      enum: ['readonly', 'readwrite']
  ]

  payload:
    type: Object

  dependencies:
    type: Object

  physical_node:
    required: true
    type: String
    enum: []

_.extend app.models,
  Component: mongoose.model 'Component', Component
