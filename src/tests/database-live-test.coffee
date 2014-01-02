testino = require('testino')
assert = require('assert')
util = require('util')

ravendb = require('../ravendb')

testDatastore =
  defaultDatabase: ravendb('http://localhost:8080')
  testDatabase: ravendb('http://localhost:8080', 'node-ravendb-tests')


module.exports = databaseLiveOperations = testino.createFixture('Database Live Operations')

databaseLiveOperations.tests =
  'should save a document with id "users/tony" into the "Users" collection': () ->
    db = testDatastore.testDatabase

    db.datastore.createDatabase db.name, (createDatabaseError, createDatabaseResponse) ->
      assert.fail "Creating test database failed: #{util.inspect(createDatabaseError)}" if createDatabaseError?

      db.saveDocument 'Users', { id: 'users/tony', firstName: 'Tony', lastName: 'Heupel'}, (error, response) ->
        assert.fail "Initial save failed: #{util.inspect(error)}" if error?

        metadata = response['@metadata']
        
        db.getDocument 'users/tony', (getError, getResponse) ->
          assert.fail "Retrieving saved document failed: #{util.inspect(getError)}" if getError?

          console.log "Got #{util.inspect(getResponse)}"

          # Modify document
          getResponse.lastName = 'Heupelsky'

          # Save modified document
          db.saveDocument null, getResponse, (saveError, saveResponse) ->
            assert.fail saveError.message if saveError?

            console.log "Saved #{util.inspect(saveResponse)}"

            db.datastore.deleteDatabase db.name, (deleteDatabaseError, deleteDatabaseResponse) ->
              assert.fail "Deleting test database failed: #{util.inspect(deleteDatabaseError)}" if deleteDatabaseError?

console.log(module.exports.run()) if require.main is module
