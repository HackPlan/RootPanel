after (done) ->
  app.models.Notification.remove
    account_id:
      $in: created_objects.accounts
  , done

describe 'model/Notification', ->
  it 'pending'
