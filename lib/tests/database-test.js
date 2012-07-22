(function() {
  var assert, fs, helpers, ravendb, remoteDatastore, vows;

  vows = require('vows');

  assert = require('assert');

  fs = require('fs');

  helpers = require('./helpers');

  ravendb = require('../ravendb');

  remoteDatastore = {
    defaultDatabase: ravendb('http://example.com'),
    foobarDatabase: ravendb('http://example.com', 'foobar')
  };

  vows.describe('Database Operations').addBatch({
    'An instance of a Database object': {
      topic: ravendb(),
      'should get a document using docs resource with the doc id': function(db) {
        helpers.mockApiCalls(db);
        return db.getDocument('users/tony', function(err, doc) {
          assert.equal(doc.verb, 'get', 'getDocument should use HTTP GET');
          return assert.ok(/\/docs\/users\/tony/.test(doc.url), 'Url should contain "/docs/{id}"');
        });
      },
      'should get the Collections list by using the terms resource against the Raven/DocumentsByEntityName index to retrieve the unique Tag values': function(db) {
        helpers.mockApiCalls(db);
        return db.getCollections(function(err, doc) {
          assert.equal(doc.verb, 'get', 'getCollections should use HTTP GET');
          return assert.ok(/\/terms\/Raven\/DocumentsByEntityName\?field=Tag/.test(doc.url), 'Url should contain "/terms/Raven/DocumentsByEntityName?field=Tag" but was "' + doc.url + '"');
        });
      },
      'should return the Key and E-Tag of the document when successfully saved': function(db) {
        var mockResponse;
        mockResponse = {
          statusCode: 201,
          body: "{ Key: 'users/tony', ETag: '00000000-0000-0900-0000-000000000016'}"
        };
        helpers.mockApiCalls(db, 201, mockResponse);
        return db.saveDocument('Users', {
          id: 'users/tony',
          firstName: 'Tony',
          lastName: 'Heupel'
        }, function(e, r) {
          return assert.deepEqual(r, mockResponse.body);
        });
      },
      'should put to the static resource when saving an attachment': function(db) {
        var content, docId, headers;
        helpers.mockApiCalls(db, 201);
        docId = "javascripts/alert.js";
        content = "alert('hi')";
        headers = {
          'Content-Type': 'text/javascript'
        };
        return db.saveAttachment(docId, content, headers, function(err, doc) {
          assert.equal(doc.verb, 'put');
          assert.ok(/\/static\/javascripts\/alert.js/.test(doc.url));
          return assert.equal(doc.body, "alert('hi')");
        });
      },
      'should work with a ReadableStream as the bodyOrReadableStream parameter': function(db) {
        var docId, readableStream;
        helpers.mockApiCalls(db, 201);
        docId = "images/foobar.jpg";
        readableStream = fs.createReadStream('./tony.jpeg');
        return db.saveAttachment(docId, readableStream, function(err, doc) {
          var body, stream;
          body = doc.body.replace(/\n/g, "");
          return stream = JSON.parse(body).body;
        });
      },
      'An instance of a non-default Database object': {
        topic: ravendb(null, 'foobar'),
        'should have a base url that includes the database resource and the database name': function(db) {
          return assert.ok(/\/databases\/foobar/.test(db.getUrl()), 'Database url should contain "/databases/{databasename}"');
        }
      },
      'An instance of a remote Database object': {
        topic: remoteDatastore,
        'should have a base url that matches the datastore url for the default database': function(datastore) {
          return assert.equal(datastore.defaultDatabase.getUrl(), 'http://example.com');
        },
        'should have a base url that matches the datastore url with the databases resource': function(datastore) {
          return assert.equal(datastore.foobarDatabase.getUrl(), 'http://example.com/databases/foobar');
        }
      }
    }
  })["export"](module);

}).call(this);
