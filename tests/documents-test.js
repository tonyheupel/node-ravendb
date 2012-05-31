// test-documents.js
var vows = require('vows')
  , assert = require('assert')


var ravendb = require('../ravendb')
var localDatastore = {   defaultDatabase:  ravendb()
                       , foobarDatabase: ravendb(null, 'foobar') 
                     }
var remoteDatastore = {   defaultDatabase: ravendb('http://example.com')
                        , foobarDatabase: ravendb('http://example.com', 'foobar')
                      }

// Intercept database api calls
localDatastore.defaultDatabase.constructor.prototype.apiGetCall = function(url, cb) {
  cb(null, { 'url': url })
}

 
vows.describe('Document Operations').addBatch({
	'An instance of a Database object': {
		topic: localDatastore.defaultDatabase,
		'should get a document using docs resource with the doc id': function(db) {
			db.getDocument('users/tony', function(err, doc) {
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
      assert.equal('http://example.com', datastore.defaultDatabase.getUrl())
    },
    'should have a base url that matches the datastore url with the databases resource': function(datastore) {
      assert.equal('http://example.com/databases/foobar', datastore.foobarDatabase.getUrl())
    }
  }
}).export(module)