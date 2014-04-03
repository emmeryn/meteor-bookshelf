Meteor.startup( ->
  if Meteor.isServer
    @pgConString = "postgres://localhost/austin"
  else pgConString = null

  # create a persistent connection with postgres to monitor notifications
  # Mediator.initialize(pgConString)
  users = new UserCollection()
  if Meteor.isServer
    users.publish.all()
    users.publish.count()
  users.subscribe.notifications()
  users.subscribe.all()
  users.subscribe.count()
)