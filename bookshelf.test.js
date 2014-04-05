if( Meteor.isServer ) {
  Tinytest.add('Bookshelf - defined on server', function (test) {
    test.notEqual( Bookshelf, undefined, 'Expected Bookshelf to be defined on the server.' );
  });
}


if( Meteor.isClient ) {
  Tinytest.add('Bookshelf - undefined on client', function (test) {
    Bookshelf = Bookshelf || undefined;
    test.isUndefined( Bookshelf, 'Expected Bookshelf to be undefined on the client.' )
  });
}