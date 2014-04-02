# Tweet Model
class @Tweet extends @Model
  # MongoDB
  @collectionName: 'tweets'
  @meteorCollection: new Meteor.Collection Tweet.collectionName

  # PostgreSQL
  tableName: Tweet.collectionName
  @fields: ['id', 'user_id', 'content']

  # Related PostgreSQL Tables
  #   * used for fetching materialized model
  @related: ['users']
  # belongs to a user
  users: ->
    if Meteor.isServer
      return @belongsTo User, 'user_id'