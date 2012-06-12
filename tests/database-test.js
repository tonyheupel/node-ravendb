// test-documents.js
var vows = require('vows')
  , assert = require('assert')
  , helpers = require('./helpers')

var ravendb = require('../ravendb')

var remoteDatastore = {   defaultDatabase: ravendb('http://example.com')
                        , foobarDatabase: ravendb('http://example.com', 'foobar')
                      }

// Intercept database api calls



vows.describe('Database Operations').addBatch({
	'An instance of a Database object': {
		topic: ravendb(),
		'should get a document using docs resource with the doc id': function(db) {
      helpers.mockApiCalls(db)

			db.getDocument('users/tony', function(err, doc) {
        assert.equal(doc.verb, 'get', 'getDocument should use HTTP GET')
        assert.ok(/\/docs\/users\/tony/.test(doc.url), 'Url should contain "/docs/{id}"')
      })
    },
    'should get the Collections list by using the terms resource against the Raven/DocumentsByEntityName index to retrieve the unique Tag values': function(db) {
      helpers.mockApiCalls(db)

      db.getCollections(function(err, doc) {
        assert.equal(doc.verb, 'get', 'getCollections should use HTTP GET')
        assert.ok(/\/terms\/Raven\/DocumentsByEntityName\?field=Tag/.test(doc.url), 'Url should contain "/terms/Raven/DocumentsByEntityName?field=Tag" but was "' + doc.url + '"')
      })
    },
    'should return the Key and E-Tag of the document when successfully saved': function(db) {
      mockResponse = { statusCode: 201, body: "{ Key: 'users/tony', ETag: '00000000-0000-0900-0000-000000000016'}" }
      helpers.mockApiCalls(db, 201, mockResponse)

      db.saveDocument('Users', { id: 'users/tony', firstName: 'Tony', lastName: 'Heupel'}, function(e,r) {
        assert.deepEqual(r, mockResponse.body)
      })
    },
    'should put to the static resource when saving an attachment': function(db) {
      helpers.mockApiCalls(db, 201)
      var docId = "javascripts/alert.js"
        , content = "alert('hi')"
        , headers = { 'Content-Type': 'text/javascript' }

      db.saveAttachment(docId, content, headers, function(err, doc) {
        assert.equal(doc.verb, 'put')
        assert.ok(/\/static\/javascripts\/alert.js/.test(doc.url))
        assert.equal(doc.body, "alert('hi')")
      })
    }
  },
  'An instance of a non-default Database object': {
    topic: ravendb(null, 'foobar'),
    'should have a base url that includes the database resource and the database name': function(db) {
      assert.ok(/\/databases\/foobar/.test(db.getUrl()), 'Database url should contain "/databases/{databasename}"')
    }
  },
  'An instance of a remote Database object': {
    topic: remoteDatastore,
    'should have a base url that matches the datastore url for the default database': function(datastore) {
      assert.equal(datastore.defaultDatabase.getUrl(), 'http://example.com')
    },
    'should have a base url that matches the datastore url with the databases resource': function(datastore) {
      assert.equal(datastore.foobarDatabase.getUrl(), 'http://example.com/databases/foobar')
    }
  }
}).export(module)