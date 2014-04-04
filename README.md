# BookshelfJS for Meteor

Bookshelf is a javascript ORM for Node.js, built on the Knex SQL query builder.

Featuring both promise based and traditional callback interfaces, it extends the Model & Collection patterns of Backbone.js, providing transaction support, eager/nested-eager relation loading, polymorphic associations, and support for one-to-one, one-to-many, and many-to-many relations.

It is designed to work well with PostgreSQL, MySQL, and SQLite3.

### Meteorite Installation
`$ mrt add bookshelf`

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

### [Bookshelf.Collection](http://bookshelfjs.org/#Collection)

