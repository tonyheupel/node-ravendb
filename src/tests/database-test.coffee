# test-documents.js
vows = require('vows')
assert = require('assert')
fs = require('fs')
helpers = require('./helpers')

ravendb = require('../ravendb')

remoteDatastore =
  defaultDatabase: ravendb('http://example.com')
  foobarDatabase: ravendb('http://example.com', 'foobar')


# Intercept database api calls


vows.describe('Database Operations').addBatch
	'An instance of a Database object':
		topic: ravendb()
		'should get a document using docs resource with the doc id': (db) ->
      helpers.mockApiCalls(db)

      db.getDocument 'users/tony', (err,doc) ->
        assert.equal doc.verb, 'get', 'getDocument should use HTTP GET'
        assert.ok /\/docs\/users\/tony/.test(doc.url), 'Url should contain "/docs/{id}"'


    'should get the Collections list by using the terms resource against the Raven/DocumentsByEntityName index to retrieve the unique Tag values': (db) ->
      helpers.mockApiCalls(db)

      db.getCollections (err, doc) ->
        assert.equal(doc.verb, 'get', 'getCollections should use HTTP GET')
        assert.ok(/\/terms\/Raven\/DocumentsByEntityName\?field=Tag/.test(doc.url), 'Url should contain "/terms/Raven/DocumentsByEntityName?field=Tag" but was "' + doc.url + '"')


    'should return the Key and E-Tag of the document when successfully saved': (db) ->
      mockResponse = { statusCode: 201, body: "{ Key: 'users/tony', ETag: '00000000-0000-0900-0000-000000000016'}" }
      helpers.mockApiCalls(db, 201, mockResponse)

      db.saveDocument 'Users', { id: 'users/tony', firstName: 'Tony', lastName: 'Heupel'}, (e,r) ->
        assert.deepEqual(r, mockResponse.body)


    'should return an error when there is an error on the call': (db) ->
      mockResponse = { statusCode: 500, body: "{ Error: 'ERROR', Message: 'There was an error' }" }
      helpers.mockApiCalls db, 500, mockResponse

      db.saveDocument 'Users', { id: 'users/tony', firstName: 'Tony', lastName: 'Heupel' }, (e,r) ->
        assert.deepEqual e, new Error(mockResponse.body)


    'should put to the static resource when saving an attachment': (db) ->
      helpers.mockApiCalls(db, 201)
      docId = "javascripts/alert.js"
      content = "alert('hi')"
      headers = { 'Content-Type': 'text/javascript' }

      db.saveAttachment docId, content, headers, (err, doc) ->
        assert.equal(doc.verb, 'put')
        assert.ok(/\/static\/javascripts\/alert.js/.test(doc.url))
        assert.equal(doc.body, "alert('hi')")


    'should work with a ReadableStream as the bodyOrReadableStream parameter' : (db) ->
      helpers.mockApiCalls(db, 201)
      docId = "images/foobar.jpg"
      readableStream = fs.createReadStream("#{__dirname}/tony.jpeg")

      db.saveAttachment docId, readableStream, (err, doc) ->
        body = doc.body.replace(/\n/g, "")
        stream = JSON.parse(body).body



  'An instance of a non-default Database object':
    topic: ravendb(null, 'foobar')
    'should have a base url that includes the database resource and the database name': (db) ->
      assert.ok(/\/databases\/foobar/.test(db.getUrl()), 'Database url should contain "/databases/{databasename}"')


  'An instance of a remote Database object':
    topic: remoteDatastore
    'should have a base url that matches the datastore url for the default database': (datastore) ->
      assert.equal(datastore.defaultDatabase.getUrl(), 'http://example.com')


    'should have a base url that matches the datastore url with the databases resource': (datastore) ->
      assert.equal(datastore.foobarDatabase.getUrl(), 'http://example.com/databases/foobar')


.export(module)
