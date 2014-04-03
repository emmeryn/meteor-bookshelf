@UserCollectionName = 'users'
@UserMeteorCollection = new Meteor.Collection UserCollectionName
@UserFields = ['id', 'username']
@UserRelated = ['tweets', 'followers', 'following']

class @Model
  # mixin that provides methods for get related fields from PostgreSQL, save to PostgreSQL, and some backbone utilities
  @include Bookshelf.PG.Model

# defined on server and client
class @User extends Model
  # PostgreSQL
  tableName: 'users'
  # used for picking the appropriate fields for model.save()
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

class @Collection
  # mixin that provides methods for get related fields from PostgreSQL, save to PostgreSQL, and some backbone utilities
  @include Bookshelf.PG.Collection
  # mixin that provides methods to persist documents to PostgreSQL and MongoDB
  @include Persist
  # mixin that provides methods to subscribe and listen to a variety of application and db notifications reactively
  @include Notifications
  # mixin that provides methods to synconize a postgreSQL and MongoDB collection
  @include Syncronize
  # mixin the allow rules class
  @include AllowRules
  # create collection with all its mixins and setup for app
  initialize: (models, options) ->
    if Meteor.isServer
      @mediator = Mediator.initialize pgConString
      @setAllowRules
        allow:
          insert: @persist.create
          update: @persist.update
          remove: @persist.remove
      @syncronize.collection()

class @UserCollection extends Collection
  model: User
  meteorCollection: UserMeteorCollection


###### Views
if Meteor.isClient
  Template.users.count = ->
    return Session.get "#{UserCollectionName}_count"

  Template.users.users = ->
    return UserMeteorCollection.find()