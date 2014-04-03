class @Notifications
  @include Logs
  @include Persist
  # parse notifications and route them to the correct method
  handle:
  # catch all notification handler, primary router
    notification: ->
      if Meteor.isServer
        # if the subscription returns a notification
        if notification = @notifications.subscribe UserCollectionName
          channel = notification[0]
          notification = notification[1]
          @log "notification:channel:#{notification.channel}"
          switch channel
            when UserCollectionName then @handle.self(notification)
            else @error "notification:channel:#{notification.channel}:uncaught", notification
    self: (notification) ->
      if Meteor.isServer
        @log "notification:channel:#{notification.channel}:operation:#{notification.operation}"
        switch notification.operation
          when 'INSERT' then @handle.insert notification
          when 'UPDATE' then @handle.update notification
          when 'DELETE' then @handle.delete notification
          else @error "notification:channel:#{notification.channel}:operation:#{notification.operation}:uncaught", notification
    insert: (notification) ->
      if Meteor.isServer
        @persist.related new @model JSON.parse notification.payload
    # Once the model is saved then insert to mongo
    update: (notification) -> @log notification
    delete: (notification) ->
      if Meteor.isServer
        instance = new @model JSON.parse notification.payload
        @persist.delete instance
  # All websocket subscriptions related to this model
  # These subscriptions are defined on the client and server
  subscribe:
    notifications: ->
      # On the client listen to notifications from the PostgreSQL server
      if Meteor.isServer
        mediator.listen UserCollectionName
        Deps.autorun @handle.notification
    all: ->
      # On the client listen to changes in the all_users publication
      if Meteor.isClient
        Meteor.subscribe "all_#{UserCollectionName}"
    count: ->
      # On the client create a collection and subscribe the the user_count publication
      if Meteor.isClient
        # set the default message for when the subcription is uninitialized
        Session.setDefault "#{UserCollectionName}_count", 'Waiting on Subsription'
        # setup User.count collection
        if @count is undefined
          @count = new Meteor.Collection "#{UserCollectionName}-count"
        # subscribe to users_count reactive publication
        Meteor.subscribe "#{UserCollectionName}_count"
        Deps.autorun (->
          models = @count.findOne()
          unless models is undefined
            Session.set "#{UserCollectionName}_count", models.count
        )
  publish:
    all: ->
      if Meteor.isClient
        @error "Data can only be published from the server."
      if Meteor.isServer
        Meteor.publish "all_#{@model.tableName}", -> @meteorCollection.find()
    count: ->
      if Meteor.isClient
        @error "Data can only be published from the server."
      if Meteor.isServer
        Meteor.publish "#{@model.tableName}_count", ->
          count = 0 # the count of all users
          initializing = true # true only when we first start
          handle = @meteorCollection.find().observeChanges
            added: =>
              count++ # Increment the count when users are added.
              @changed "#{@model.tableName}-count", 1, {count} unless initializing
            removed: =>
              count-- # Decrement the count when users are removed.
              @changed "#{@model.tableName}-count", 1, {count}
          initializing = false
          # Call added now that we are done initializing. Use the id of 1 since
          # there is only ever one object in the collection.
          @added "#{@model.tableName}-count", 1, {count}
          # Let the client know that the subscription is ready.
          @ready()
          # Stop the handle when the user disconnects or stops the subscription.
          # This is really important or you will get a memory leak.
          @onStop -> handle.stop()