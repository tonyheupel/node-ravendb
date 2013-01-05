testino = require('testino')
assert = require('assert')
fs = require('fs')
helpers = require('./helpers')

ravendb = require('../ravendb')

remoteDatastore =
  defaultDatabase: ravendb('http://example.com')
  foobarDatabase: ravendb('http://example.com', 'foobar')


module.exports = databaseOperations = testino.createFixture('Database Operations')

databaseOperations.tests =
  'should get a document using docs resource with the doc id': () ->
    db = ravendb()
    helpers.mockApiCalls(db)

    db.getDocument 'users/tony', (err,doc) ->
      assert.equal doc.verb, 'get', 'getDocument should use HTTP GET'
      assert.ok /\/docs\/users\/tony/.test(doc.url), 'Url should contain "/docs/{id}"'


  'should get the Collections list by using the terms resource against the Raven/DocumentsByEntityName index to retrieve the unique Tag values': () ->
    db = ravendb()
    helpers.mockApiCalls(db)

    db.getCollections (err, doc) ->
      assert.equal(doc.verb, 'get', 'getCollections should use HTTP GET')
      assert.ok(/\/terms\/Raven\/DocumentsByEntityName\?field=Tag/.test(doc.url), 'Url should contain "/terms/Raven/DocumentsByEntityName?field=Tag" but was "' + doc.url + '"')


  'should return the Key and E-Tag of the document when successfully saved': () ->
    db = ravendb()
    basicResponseBody = { Key: "users/tony", ETag: "00000000-0000-0900-0000-000000000016" }
    mockResponse = { statusCode: 201, body: JSON.stringify(basicResponseBody) }
    helpers.mockApiCalls(db, 201, mockResponse)

    db.saveDocument 'Users', { id: 'users/tony', firstName: 'Tony', lastName: 'Heupel'}, (e,r) ->
      metadata = r['@metadata']
      assert.equal(metadata.key, basicResponseBody.Key, "@metadata/key should be set properly")
      assert.equal(metadata.etag, basicResponseBody.ETag, "@metadata/etag should be set properly")


  'should return an error when there is an error on the call': () ->
    db = ravendb()
    mockResponse = { statusCode: 500, body: "{ Error: 'ERROR', Message: 'There was an error' }" }
    helpers.mockApiCalls db, 500, mockResponse

    db.saveDocument 'Users', { id: 'users/tony', firstName: 'Tony', lastName: 'Heupel' }, (e,r) ->
      assert.deepEqual e, new Error(mockResponse.body)


  'should put to the static resource when saving an attachment': () ->
    db = ravendb()
    helpers.mockApiCalls(db, 201)
    docId = "javascripts/alert.js"
    content = "alert('hi')"
    headers = { 'Content-Type': 'text/javascript' }

    db.saveAttachment docId, content, headers, (err, doc) ->
      assert.equal(doc.verb, 'put')
      assert.ok(/\/static\/javascripts\/alert.js/.test(doc.url))
      assert.equal(doc.body, "alert('hi')")


  'should work with a ReadableStream as the bodyOrReadableStream parameter' : () ->
    db = ravendb()
    helpers.mockApiCalls(db, 201)
    docId = "images/foobar.jpg"
    readableStream = fs.createReadStream("#{__dirname}/tony.jpeg")

    db.saveAttachment docId, readableStream, (err, doc) ->
      body = doc.body.replace(/\n/g, "")
      stream = JSON.parse(body).body

  'should handle a non-JSON response when receiving an error on saveDocument' : () ->
    db = ravendb()
    body = "<html><title>Permission Denied</title><body>You shall not pass!</body></html>"
    status = 401
    helpers.mockApiCalls(db, status, { statusCode: status, body: body })

    db.saveDocument null, { id: 'some_id', value: 'some value' }, (err, resp) ->
      assert.equal(null, resp)
      assert.equal(err.message, "Unable to create document: #{status} - #{body}")


  'should handle a non-JSON response when receiving an error on getDocumentCount' : () ->
    db = ravendb()
    body = "<html><title>Permission Denied</title><body>You shall not pass!</body></html>"
    status = 401
    helpers.mockApiCalls(db, status, { statusCode: status, body: body })

    db.getDocumentCount null, (err, resp) ->
      assert.equal(null, resp)
      assert.equal(err.message, "Unable to get document count: #{status} - #{body}")


  'A non-default Database object should have a base url that includes the database resource and the database name': () ->
    db = ravendb(null, 'foobar')
    assert.ok(/\/databases\/foobar/.test(db.getUrl()), 'Database url should contain "/databases/{databasename}"')


  'A remote Database object should have a base url that matches the datastore url for the default database': (datastore) ->
    assert.equal(remoteDatastore.defaultDatabase.getUrl(), 'http://example.com')


  'A remote Database object should have a base url that matches the datastore url with the databases resource': (datastore) ->
    assert.equal(remoteDatastore.foobarDatabase.getUrl(), 'http://example.com/databases/foobar')


console.log(module.exports.run()) if require.main is module
