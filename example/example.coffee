Meteor.startup(->
  if Meteor.isServer
    # Initialize PostgreSQL connection and create client pool for Bookshelf
    Bookshelf.PG = Bookshelf.initialize
      client: 'pg',
      connection:
        host: 'localhost'
        user: 'austin'
)