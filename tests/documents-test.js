// test-documents.js
var vows = require('vows')
  , assert = require('assert')


var ravendb = require('../ravendb')
var ds = ravendb.use('http://localhost:8080')
var db = ds.defaultDb

ravendb.Database.prototype.apiGetCall = function(url, cb) {
  cb(null, { 'url': url })
}

 
vows.describe('Document Operations').addBatch({
	'An instance of a Database object': {
		topic: db,
		'should get a document using docs resource with the doc id': function(db) {
			db.getDocument('users/tony', function(err, doc) {
        assert.equal('http://localhost:8080/docs/users/tony', doc.url)
		  })
    }
  }
}).export(module)