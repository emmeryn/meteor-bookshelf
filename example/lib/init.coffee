if Meteor.isServer
  # Initialize PostgreSQL connection and create client pool for Bookshelf
  Bookshelf.PG = Bookshelf.initialize
    client: 'pg',
    connection:
      host: 'localhost'
      user: 'austin'

  class @Model extends Bookshelf.PG.Model

if Meteor.isClient
  # Stub Bookshelf on the client
  class @Model