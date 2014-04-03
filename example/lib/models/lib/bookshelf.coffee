if Meteor.isServer
  # Initialize PostgreSQL connection and create client pool for Bookshelf
  Bookshelf.PG = Bookshelf.initialize
    client: 'pg',
    connection:
      host: 'localhost'
      user: 'austin'

if Meteor.isClient
  # Stub bookshelf on the client
  @Bookshelf =
    PG:
      Model: {}
      Collection: {}