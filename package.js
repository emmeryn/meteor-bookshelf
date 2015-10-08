Package.describe({
  summary: "A Backbone based PostgreSQL ORM for packaged for Meteor"
});

Package.onUse(function (api, where) {
  Npm.depends({
    // [node-postgres connector](https://github.com/brianc/node-postgres)
    pg: '4.4.2',
    // [SQL ORM based on Backbone](http://bookshelfjs.org)
    bookshelf: '0.8.2'
  });

  api.use([
    'underscore'
  ],['server']);

  api.addFiles([
    'bookshelf.js'
  ], ['server']);

  api.export([
    'Bookshelf'
  ], ['server']);
});


Package.onTest(function (api) {
  api.use(['bookshelf', 'tinytest', 'test-helpers'], ['client', 'server']);
  api.addFiles('bookshelf.test.js', ['client', 'server']);
});