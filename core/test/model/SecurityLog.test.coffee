after (done) ->
  app.models.SecurityLog.remove
    account_id:
      $in: created_objects.accounts
  , done

describe 'model/SecurityLog', ->
  it 'pending'
