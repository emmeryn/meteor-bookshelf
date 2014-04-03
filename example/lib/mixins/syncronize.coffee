# Fetch the entire users table and its related fields and insert into MongoDB
class @Syncronize
  @include Logs
  @include Persist
  syncronize:
    collection: _.once(->
      if Meteor.isClient
        @error "A collection can only be sync'd from the server."
      if Meteor.isServer
        # build a complete user collection with all related fields
        @log "#{UserCollectionName}:sync"
        User.collection().fetch(
          withRelated: UserRelated
        ).then( @persist.collection
        , (err)->
          @log "#{UserCollectionName}:sync:error"
          @log err
        )
    )