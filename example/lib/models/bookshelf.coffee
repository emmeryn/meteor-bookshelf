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

class @BookshelfModel extends Bookshelf.PG.Model
class @BookshelfCollection extends Bookshelf.PG.Collection
  fetchSync: (options) ->
    self = @
    Async.runSync( ( done ) ->
      self.fetch( options )
      .then (result, error) ->
        if error
          self.error "#{self.model.getTableName()}:collection:fetch:error", error
        done error, result
    )


# mixin that provides methods for get related fields from PostgreSQL, save to PostgreSQL, and some backbone utilities
class @Model extends Mixen( BookshelfModel, Logs )
  # static access to the tableName instance property
  @getTableName: ->
    self = @
    return new self().tableName

class @Collection extends Mixen( AllowRules, Notifications, Persist, BookshelfCollection, Logs )
  # create collection with all its mixins and setup for app
  initialize: (models, options) ->
    self = @
    self.mediator = Mediator.initialize()
    if Meteor.isServer
      self.setAllowRules()
      self.syncronize_collection()
    self.log "#{self.model.getTableName()}:collection:initialized"

  getTableName: ->
    self = @
    self.model.getTableName()

  allow:
    insert: @persist_create
    update: @persist_update
    remove: @persist_remove