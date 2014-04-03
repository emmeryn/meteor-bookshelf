class @Persist
  @include Logs
  # Create a PostgreSQL record from a MongoDB document
  persist:
    create: (userId, doc)->
      if Meteor.isClient
        @error "A document can only be persisted from the server."
      if Meteor.isServer
        # Calling save() persists the model to PostgreSQL
        # Notice that this only saves the model, not its related models
        @log "persist:create:#{doc._id}"
        new User().save _.pick(doc, UserFields)
        # Once the model is saved then insert to mongo
        .then( @persist.related
          , (err)-> @error "persist:create:#{doc._id}:error", err
          )
        return false
    # Insert a PostgreSQL model into MongoDB
    insert: Meteor.bindEnvironment( (model) ->
      if Meteor.isClient
        @error "A document can only be persisted from the server."
      if Meteor.isServer
        # insert the model into MongoDB
        _id = UserMeteorCollection.upsert model.toJSON()
        @log "#{model.tableName}:persist:insert:#{_id}"
        @log UserMeteorCollection.find({ id: model.id }).fetch()
    )
    upsert: Meteor.bindEnvironment( (model) ->
      if Meteor.isClient
        @error "A document can only be persisted from the server."
      if Meteor.isServer
        # upsert the model into MongoDB
        result = UserMeteorCollection.upsert { id: model.id }, { $set: model.toJSON() }
        @log "#{model.tableName}:persist:upsert:result"
        @log result
        @log UserMeteorCollection.find({ id: model.id }).fetch()
    )
    update: (userId, docs, fields, modifier) ->
      if Meteor.isClient
        @error "A document can only be persisted from the server."
      if Meteor.isServer
        @log "#{UserCollectionName}:persist:update"
        @log
          userId: userId
          docs: docs
          fields: fields
          modifier: modifier
        return false
    remove: Meteor.bindEnvironment( (userId, docs) ->
      if Meteor.isClient
        @error "A document can only be persisted from the server."
      if Meteor.isServer
        @log "#{UserCollectionName}:persist:remove"
        return false
    )
    delete: Meteor.bindEnvironment( (model) ->
      if Meteor.isClient
        @error "A document can only be persisted from the server."
      if Meteor.isServer
        @log "#{UserCollectionName}:persist:delete"
        UserMeteorCollection.remove id: model.id
    )
    # Push a PostgreSQL collection into mongoDB
    collection: Meteor.bindEnvironment( (collection)->
      if Meteor.isClient
        @error "A document can only be persisted from the server."
      if Meteor.isServer
        @log "#{UserCollectionName}:persist:collection"
        # upsert will create a new model if none exists or merge the model with the new model object
        collection.toArray().forEach @persist.upsert
    )
    related: Meteor.bindEnvironment( (model) ->
      if Meteor.isClient
        @error "A document can only be persisted from the server."
      if Meteor.isServer
        @log "#{model.tableName}:persist:related:#{model.id}"
        # retrieve an instance of this model with all of its related fields from postgres
        model.fetch
          withRelated: UserRelated
        # Once the related fields have been fetched
        # bindEnvironment is necssary again as this is another promise
        .then( @persist.upsert
          , (err)->
            @log "#{UserCollectionName}:persist:related:#{model.id}:error"
            @log err
          )
    )
