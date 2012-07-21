# datastore-test.js
Datastore = require('../datastore')
vows = require('vows')
assert = require('assert')
helpers = require('./helpers')

vows.describe('Datastore Operations').addBatch
  'A Datastore object dealing with Tenants':
    topic: new Datastore()
    'should be able to create another database tenant': (ds) ->
      helpers.mockApiCalls(ds.defaultDatabase, 201)  # 201 - Created

      ds.createDatabase 'Foobar', '~/Tenants/FoobarDatabase', (error, result) ->
        result = JSON.parse(result)
        assert.equal result.url, 'http://localhost:8080/docs/Raven/Databases/Foobar'
        assert.equal result.verb, 'put'
        assert.equal result.body, "{ Settings: { 'Raven/DataDir': '~/Tenants/FoobarDatabase' } }"


    'should create a database tenant with a default Raven/DataDir of "~/Tenants/{database name}" value if not provided': (ds) ->
      helpers.mockApiCalls(ds.defaultDatabase, 201)  # 201 - Created

      ds.createDatabase 'Foobar', (error, result) ->
        result = JSON.parse(result)
        assert.equal result.url, 'http://localhost:8080/docs/Raven/Databases/Foobar'
        assert.equal result.verb, 'put'
        assert.equal result.body, "{ Settings: { 'Raven/DataDir': '~/Tenants/Foobar' } }"


    'should be able to delete a database tenant': (ds) ->
      helpers.mockApiCalls(ds.defaultDatabase, 204)  # 204 - no content

      ds.deleteDatabase 'Foobar', (error, result) -> 
        result = JSON.parse(result)
        assert.equal result.url, 'http://localhost:8080/docs/Raven/Databases/Foobar'
        assert.equal result.verb, 'delete'

.export(module)
