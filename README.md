# BookshelfJS for Meteor

Bookshelf is a javascript ORM for Node.js, built on the Knex SQL query builder.

Featuring both promise based and traditional callback interfaces, it extends the Model & Collection patterns of Backbone.js, providing transaction support, eager/nested-eager relation loading, polymorphic associations, and support for one-to-one, one-to-many, and many-to-many relations.

It is designed to work well with PostgreSQL, MySQL, and SQLite3.

### Meteorite Installation
`$ mrt add bookshelf`

### Example App
This package comes with an example app that showcases two completely arbitrary models.

Using Bookshelf in this manner allows you to use Meteor reactivity and MongoDB with PostgreSQL relational data.

Enjoy!

#### Setup PostgreSQL
The example app includes [schema.sql](example/schema.sql).

Import the schema into your PostgreSQL db to bootstrap the example app. ( Requires PostgreSQL 9.1 or greater )

Be sure to set the user assignment in `schema.sql` to your PostgreSQL user.

#### Run Example
`$ cd example && meteor`

#### Add data to PostgreSQL via Client Insert
Add data to your PostgreSQL DB by opening the browser console and running `$ User.meteorCollection.insert({"username":"austinrivas"});`

You should see this in the server console

```shell
> users:save:X9FvpF9w9qNbgnzQ7
> users:persist:related:295
> mediator:notification:users_INSERT
> { channel: 'users',
    operation: 'INSERT',
    payload: '{"username":"austinrivas","id":295}'
  }
> users:notification:channel:users
> users:notification:channel:users:operation:INSERT
> { channel: 'users',
    operation: 'INSERT',
    payload: '{"username":"austinrivas","id":295}'
  }
> users:insert:6M5Lc5a8ePQLF3kjq
> { username: 'austinrivas',
    id: 295,
    following: [],
    followers: [],
    tweets: [],
    _id: '6M5Lc5a8ePQLF3kjq'
  }
```

You should also be able to view this record in you PostgreSQL table `users`

#### What just happened?
The `User` model class intercepts the collection insert using the `Meteor.Collection` allow rules.
    * When a client inserts to a client meteor collection the insert is caught by the collection.allow rules and persisted to PostgreSQL
    * If the PostgreSQL write is successful the related fields are fetched and the joined doc is saved to MongoDB.
    * Any external writes to the watched PostgreSQL tables trigger a PostgreSQL event that is caught by the listening models.
    * When a notification is caught by a model, the model fetches the related fields and upserts the updated model to its MongoDB collection.
    * Meteor automatically updates the UI when the underlying MongoDB collection is updated.

#### What is `Mediator`?
`Mediator` is a simple notification class that allows models to subscribe to notifications from other models and your PostgreSQL db.

`Mediator` is provided as an example to demonstrate the power of PostgreSQL notifications when tied to relation models.

### [Example PostgreSQL Schema](example/example_schema.sql)
This schema includes
    * User Table
        * id
        * username
    * Tweets Table - A user can have many tweets
        * id
        * user_id (user.id)
        * content
    * Followers (Pivot) Table - A user can follow many, and have many followers
        * id
        * follower (user.id)
        * followee (user.id)
    * Triggers
        Fired on on
            * INSERT
            * UPDATE
            * DELETE
        Sends notification via `notify_trigger()` PostgreSQL Trigger Function
            * notification channel `tableName_operation` e.g. `users_INSERT`
            * payload is the record in JSON

## [BookshelfJS Official Docs](http://bookshelfjs.org/)

### [Bookshelf.initialize](http://bookshelfjs.org/#Initialize)
Initializing Bookshelf creates a client pool that will be used for all of your future queries.

I like to wrap `Bookshelf.initialize` in an `_.once` to prevent multiple calls.
  * Note that if you are creating multiple clients you should not do this.

```coffeescript
Bookshelf.initialize = _.once Bookshelf.initialze
```

Another common best practice to to save the client returned by `initialze` as a property on `Bookshelf`.

```
Bookshelf.PG = Bookshelf.initialize
    client: 'pg',
    connection:
      host: 'localhost'
      user: 'austin'
```

### [Bookshelf.Model](http://bookshelfjs.org/#Model)
I declare the model on both the client and the server like so

```coffeescript
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
```

This allows me to reuse model methods that do not require the ORM

### [Bookshelf.Collection](http://bookshelfjs.org/#Collection)

