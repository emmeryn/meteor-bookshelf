Package.describe({
  summary: "A Backbone based PostgreSQL ORM for packaged for Meteor"
});

Package.on_use(function (api, where) {
  Npm.depends({
    // [node-postgres connector](https://github.com/brianc/node-postgres)
    pg: '2.11.1',
    // [SQL ORM based on Backbone](http://bookshelfjs.org)
    bookshelf: '0.6.8'
  });

  api.use([
    'underscore'
  ],['server']);

  api.add_files([
    'bookshelf.js'
  ], ['server']);

  api.export([
    'Bookshelf'
  ], ['server']);
});


Package.on_test(function (api) {
  api.use(['bookshelf', 'tinytest', 'test-helpers'], ['client', 'server']);
  api.add_files('bookshelf.test.js', ['client', 'server']);
});