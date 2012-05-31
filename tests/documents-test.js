// test-documents.js
var vows = require('vows')
  , assert = require('assert')


var ravendb = require('../ravendb')
var defaultDatabase = ravendb()
var foobarDatabase = ravendb(null, 'foobar')

// Intercept database api calls
defaultDatabase.constructor.prototype.apiGetCall = function(url, cb) {
  cb(null, { 'url': url })
}

 
vows.describe('Document Operations').addBatch({
	'An instance of a default Database object': {
		topic: defaultDatabase,
		'should get a document using docs resource with the doc id': function(db) {
			db.getDocument('users/tony', function(err, doc) {
        assert.equal('http://localhost:8080/docs/users/tony', doc.url)
		  })
    }
  },
  'An instance of a non-default Database object': {
    topic: foobarDatabase,
    'should get a document using databases and resource with doc id': function(db) {
      db.getDocument('users/tony', function(err, doc) {
        assert.equal('http://localhost:8080/databases/foobar/docs/users/tony', doc.url)
      })
    }
  }
}).export(module)