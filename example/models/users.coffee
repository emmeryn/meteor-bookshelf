# defined on server and client
class @User extends Model
  # MongoDB
  @collectionName: 'users'
  @meteorCollection: new Meteor.Collection User.collectionName

  # PostgreSQL
  tableName: User.collectionName
  # used for picking the appropriate fields for model.save()
  # TODO : replace with simpleSchema definition
  @fields: ['id', 'username']

  # Related PostgreSQL Tables
  #   * used for fetching materialized model
  @related: ['tweets', 'followers', 'following']
  tweets: ->
    if Meteor.isServer
      @hasMany Tweet, 'user_id'
  # Notice that user is self referenced, this is due to followers being a user pivot table
  followers: ->
    if Meteor.isServer
      @belongsToMany User, 'followers', 'followee', 'follower'
  following: ->
    if Meteor.isServer
      @belongsToMany User, 'followers', 'follower', 'followee'

  @persist:
    # Create a PostgreSQL record from a MongoDB document
    create: (userId, doc)->
      if Meteor.isServer
        # Calling save() persists the model to PostgreSQL
        # Notice that this only saves the model, not its related models
        Mediator.log "#{User.collectionName}:persist:create:#{doc._id}"
        new User().save _.pick(doc, User.fields)
        # Once the model is saved then insert to mongo
        .then( User.persist.related
        , (err)->
          Mediator.log "#{User.collectionName}:persist:create:#{doc._id}:error"
          Mediator.log err
        )
        return false
    # Insert a PostgreSQL model into MongoDB
    insert: Meteor.bindEnvironment( (model) ->
      if Meteor.isServer
        # insert the model into MongoDB
        _id = User.meteorCollection.upsert model.toJSON()
        Mediator.log "#{model.tableName}:persist:insert:#{_id}"
        Mediator.log User.meteorCollection.find({ id: model.id }).fetch()
    )
    upsert: Meteor.bindEnvironment( (model) ->
      if Meteor.isServer
        # upsert the model into MongoDB
        result = User.meteorCollection.upsert { id: model.id }, { $set: model.toJSON() }
        Mediator.log "#{model.tableName}:persist:upsert:result"
        Mediator.log result
        Mediator.log User.meteorCollection.find({ id: model.id }).fetch()
    )
    update: (userId, docs, fields, modifier) ->
      if Meteor.isServer
        Mediator.log "#{User.collectionName}:persist:update"
        Mediator.log
          userId: userId
          docs: docs
          fields: fields
          modifier: modifier
        return false
    remove: Meteor.bindEnvironment( (userId, docs) ->
      if Meteor.isServer
        Mediator.log "#{User.collectionName}:persist:remove"
        return false
    )
    delete: Meteor.bindEnvironment( (model) ->
      if Meteor.isServer
        Mediator.log "#{User.collectionName}:persist:delete"
        User.meteorCollection.remove id: model.id
    )
    # Push a PostgreSQL collection into mongoDB
    collection: Meteor.bindEnvironment( (collection)->
      if Meteor.isServer
        Mediator.log "#{User.collectionName}:persist:collection"
        # upsert will create a new model if none exists or merge the model with the new model object
        collection.toArray().forEach User.persist.upsert
    )
    related: Meteor.bindEnvironment( (model) ->
      if Meteor.isServer
        Mediator.log "#{model.tableName}:persist:related:#{model.id}"
        # retrieve an instance of this model with all of its related fields from postgres
        model.fetch
          withRelated: User.related
        # Once the related fields have been fetched
        # bindEnvironment is necssary again as this is another promise
        .then( User.persist.upsert
        , (err)->
          Mediator.log "#{User.collectionName}:persist:related:#{model.id}:error"
          Mediator.log err
        )
    )
  @setAllowRules: ->
    if Meteor.isServer
      # Allow rules control the clients ability to write to MongoDB
      # This is where the write to PostgreSQL occurs
      # If the PostgreSQL write fails
      #   * then the allow rule fails
      #   * and the write is invalidated on the client
      # Other allow rules may include role validation, write access, and much more
      User.meteorCollection.allow
      # when a client inserts into the user collection
      #   * userId is the user on the client
      #     * userId is really useful for checking authorization on data changes
      #   * doc is the MongoDB document being inserted
      #     * this document has already been created on the client
      #     * if this allow rule fails the client version will be invalidated and removed
        insert: User.persist.create
        update: User.persist.update
        remove: User.persist.remove

  @publish:
    all: ->
      if Meteor.isServer
        Meteor.publish "all_#{User.collectionName}", -> User.meteorCollection.find()
    count: ->
      if Meteor.isServer
        Meteor.publish "#{User.collectionName}_count", ->
          count = 0 # the count of all users
          initializing = true # true only when we first start
          handle = User.meteorCollection.find().observeChanges
            added: =>
              count++ # Increment the count when users are added.
              @changed "#{User.collectionName}-count", 1, {count} unless initializing
            removed: =>
              count-- # Decrement the count when users are removed.
              @changed "#{User.collectionName}-count", 1, {count}
          initializing = false
          # Call added now that we are done initializing. Use the id of 1 since
          # there is only ever one object in the collection.
          @added "#{User.collectionName}-count", 1, {count}
          # Let the client know that the subscription is ready.
          @ready()
          # Stop the handle when the user disconnects or stops the subscription.
          # This is really important or you will get a memory leak.
          @onStop -> handle.stop()

  @handle:
    notification: ->
      if Meteor.isServer
        # if the subscription returns a notification
        if notification = Mediator.subscribe User.collectionName
          channel = notification[0]
          notification = notification[1]
          Mediator.log "#{User.collectionName}:notification:channel:#{notification.channel}"
          switch channel
            when User.collectionName then User.handle.self(notification)
            else Mediator.log "#{User.collectionName}:notification:channel:#{notification.channel}:uncaught"
    self: (notification) ->
      if Meteor.isServer
        Mediator.log "#{User.collectionName}:notification:channel:#{notification.channel}:operation:#{notification.operation}"
        switch notification.operation
          when 'INSERT' then User.handle.insert(notification)
          when 'UPDATE' then User.handle.update(notification)
          when 'DELETE' then User.handle.delete(notification)
          else Mediator.log "#{User.collectionName}:notification:channel:#{notification.channel}:operation:#{notification.operation}:uncaught"
    insert: (notification) ->
      if Meteor.isServer
        User.persist.related new User JSON.parse notification.payload
        # Once the model is saved then insert to mongo
    update: (notification) ->
      Mediator.log notification
    delete: (notification) ->
      if Meteor.isServer
        user = new User JSON.parse notification.payload
        User.persist.delete user


  # All websocket subscriptions related to this model
  # These subscriptions are defined on the client and server
  @subscribe:
    notifications: ->
      # On the client listen to notifications from the PostgreSQL server
      if Meteor.isServer
        Mediator.listen User.collectionName
        Deps.autorun User.handle.notification
    all: ->
      # On the client listen to changes in the all_users publication
      if Meteor.isClient
        Meteor.subscribe "all_#{User.collectionName}"
    count: ->
      # On the client create a collection and subscribe the the user_count publication
      if Meteor.isClient
        # set the default message for when the subcription is uninitialized
        Session.setDefault "#{User.collectionName}_count", 'Waiting on Subsription'
        # setup User.count collection
        if User.count is undefined
          User.count = new Meteor.Collection "#{User.collectionName}-count"
        # subscribe to users_count reactive publication
        Meteor.subscribe "#{User.collectionName}_count"
        Deps.autorun (->
          users = User.count.findOne()
          unless users is undefined
            Session.set "#{User.collectionName}_count", users.count
        )

  # Fetch the entire users table and its related fields and insert into MongoDB
  @syncronizeMongoDB: ->
    if Meteor.isServer
      # build a complete user collection with all related fields
      Mediator.log "#{User.collectionName}:sync"
      User.collection().fetch(
        withRelated: User.related
      ).then( User.persist.collection
      , (err)->
        Mediator.log "#{User.collectionName}:sync:error"
        Mediator.log err
      )

  # setup subscriptions / publications
  @initialize: _.once ->
    Mediator.log "#{User.collectionName}:initialize"
    if Meteor.isServer
      User.setAllowRules()
      User.syncronizeMongoDB()
      User.publish.all()
      User.publish.count()
    User.subscribe.notifications()

###### Views
if Meteor.isClient
  Template.users.count = ->
    return Session.get "#{User.collectionName}_count"

  Template.users.users = ->
    return User.meteorCollection.find()