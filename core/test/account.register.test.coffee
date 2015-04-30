describe 'account.register', ->
  agent = createAgent
    baseUrl: '/account'

  account_id = null
  username = null
  password = null
  email = null
  token = null

  it 'GET login', ->
    agent.get '/login'

  it 'GET register', ->
    agent.get '/register'

  it 'POST register', ->
    {username, password, email} = randomAccount()

    agent.post '/register',
      json:
        username: username
        email: email
        password: password
    ,
      headers:
        'set-cookie': /token=/
      body:
        account_id: /\w{24}/
        token: /\w{64}/
    .then ({body}) ->
      {account_id, token} = body

  it 'POST register with existed username', ->
    agent.post '/register',
      json:
        username: username
        email: randomAccount().email
        password: password
    ,
      error: 'username exist'

  it 'POST register with invalid email', ->
    agent.post '/register',
      json:
        username: randomAccount().username
        email: 'gmail.com'
        password: password
    ,
      error: 'invalid email'

  it 'POST login', ->
    agent.post '/login',
      json:
        username: username
        password: password
    ,
      headers:
        'set-cookie': /token=/
      body:
        account_id: /\w{24}/
        token: /\w{64}/

  it 'GET account', ->
    agent.get '/',
      headers:
        token: token
    ,
      body:
        _id: /\w{24}/
        username: username

  it 'POST logout', ->
    agent.post '/logout',
      headers:
        token: token
    ,
      headers:
        'set-cookie': /token=;/

  it 'POST login with email', ->
    agent.post '/login',
      json:
        username: email
        password: password
    ,
      headers:
        'set-cookie': /token=/
      body:
        account_id: /\w{24}/
        token: /\w{64}/

  it 'POST login with username does not exist', ->
    agent.post '/login',
      json:
        username: randomAccount().username
        password: password
    ,
      error: 'wrong password'

  it 'POST login with invalid password', ->
    agent.post '/login',
      json:
        username: username
        password: 'invalid password'
    ,
      error: 'wrong password'
