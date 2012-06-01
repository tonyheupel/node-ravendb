// test-documents.js
var vows = require('vows')
  , assert = require('assert')
  , helpers = require('./test-helpers')

var ravendb = require('../ravendb')
var localDatastore = {   defaultDatabase:  ravendb()
                       , foobarDatabase: ravendb(null, 'foobar') 
                     }
var remoteDatastore = {   defaultDatabase: ravendb('http://example.com')
                        , foobarDatabase: ravendb('http://example.com', 'foobar')
                      }

// Intercept database api calls


 
vows.describe('Document Operations').addBatch({
	'An instance of a Database object': {
		topic: localDatastore.defaultDatabase,
		'should get a document using docs resource with the doc id': function(db) {
      helpers.mockApiCalls(localDatastore.defaultDatabase)

			db.getDocument('users/tony', function(err, doc) {
        assert.equal(doc.verb, 'get', 'getDocument should use HTTP GET')
        assert.ok(/\/docs\/users\/tony/.test(doc.url), 'Url should contain "/docs/{id}"')
		  })
    }
  },
  'An instance of a non-default Database object': {
    topic: localDatastore.foobarDatabase,
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
  },
  'An instance of a Database object': {
    topic: localDatastore.defaultDatabase,
    'should return the Key and E-Tag of the document when successfully saved': function(db) {
      mockResponse = { statusCode: 201, body: { Key: 'users/tony', ETag: '00000000-0000-0900-0000-000000000016'} }
      helpers.mockApiCalls(localDatastore.defaultDatabase, 201, mockResponse)

      db.saveDocument('Users', { id: 'users/tony', firstName: 'Tony', lastName: 'Heupel'}, function(e,r) {
        assert.deepEqual(r, mockResponse.body)
      })
    }
  }
}).export(module)