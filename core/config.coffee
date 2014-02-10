module.exports =
  web:
    port: 3000

  db:
    type: 'mongo'
    server: '/home/rpadmin/mongod.sock'
    user: 'rpadmin'
    passwd: 'passwd'
    