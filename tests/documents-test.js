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
helpers.mockApiCalls(localDatastore.defaultDatabase)

 
vows.describe('Document Operations').addBatch({
	'An instance of a Database object': {
		topic: localDatastore.defaultDatabase,
		'should get a document using docs resource with the doc id': function(db) {
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
  }
}).export(module)