# datastore-test.js
Datastore = require('../datastore')
testino = require('testino')
assert = require('assert')
helpers = require('./helpers')

module.exports = datastoreOperations = testino.createFixture('datastoreOperations')

# Helper method
createDefaultDatabase = (datastore) ->

# Tests
datastoreOperations.tests =
  # TODO: This functionality seems to work, but the testing helpers are not working right now
  #  'should be able to create another database tenant': () ->
  #    ds = new Datastore()
  #    helpers.mockApiCalls(ds.defaultDatabase, 201) # 201 - Created
  #
  #    ds.createDatabase 'Foobar', '~/Tenants/FoobarDatabase', (error, result) ->
  #      result = JSON.parse(result)
  #      assert.equal result.url, 'http://localhost:8080/docs/Raven/Databases/Foobar'
  #      assert.equal result.verb, 'put'
  #      assert.equal result.body, "{ Settings: { 'Raven/DataDir': '~/Tenants/FoobarDatabase' } }"
  #
  #
  #  'should create a database tenant with a default Raven/DataDir of "~/Tenants/{database name}" value if not provided': () ->
  #    ds = new Datastore()
  #    helpers.mockApiCalls(ds.defaultDatabase, 201)  # 201 - Created
  #
  #    ds.createDatabase 'Foobar', (error, result) ->
  #      result = JSON.parse(result)
  #      assert.equal result.url, 'http://localhost:8080/docs/Raven/Databases/Foobar'
  #      assert.equal result.verb, 'put'
  #      assert.equal result.body, "{ Settings: { 'Raven/DataDir': '~/Tenants/Foobar' } }"


  'should be able to delete a database tenant': () ->
    ds = new Datastore()
    helpers.mockApiCalls(ds.defaultDatabase, 204)  # 204 - no content

    ds.deleteDatabase 'Foobar', (error, result) ->
      result = JSON.parse(result)
      assert.equal result.url, 'http://localhost:8080/docs/Raven/Databases/Foobar'
      assert.equal result.verb, 'delete'


console.log(module.exports.run()) if require.main is module
