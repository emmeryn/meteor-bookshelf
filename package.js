Package.describe({
  summary: "A Backbone based PostgreSQL ORM for packaged for Meteor"
});

Package.on_use(function (api, where) {
  api.use([
    'underscore'
  ],['client', 'server'])

  api.use([
    'postgresql'
  ], ['server']);

  Npm.depends({
    //
    pg: '2.11.1',
    // [SQL ORM based on Backbone](http://bookshelfjs.org)
    bookshelf: '0.6.8'
  });

  api.add_files(['bookshelf.js'], ['server']);

  api.export(['Bookshelf'], ['server']);
});

Package.on_test(function (api) {
  api.use('bookshelf');
});
