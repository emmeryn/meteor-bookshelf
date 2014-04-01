Package.describe({
  summary: "A Backbone based PostgreSQL ORM for packaged for Meteor"
});

Package.on_use(function (api, where) {
  api.use([
    'postgresql'
  ], ['server']);

  Npm.depends({
    // [SQL ORM based on Backbone](http://bookshelfjs.org)
    bookshelf: '0.6.8'
  });

  api.add_files(['bookshelf.coffee'], ['server']);

  api.export(['Bookshelf'], ['server']);
});

Package.on_test(function (api) {
  api.use('bookshelf');
});
