(function() {
  var Datastore, assert, helpers, vows;

  Datastore = require('../datastore');

  vows = require('vows');

  assert = require('assert');

  helpers = require('./helpers');

  vows.describe('Datastore Operations').addBatch({
    'A Datastore object dealing with Tenants': {
      topic: new Datastore(),
      'should be able to create another database tenant': function(ds) {
        helpers.mockApiCalls(ds.defaultDatabase, 201);
        return ds.createDatabase('Foobar', '~/Tenants/FoobarDatabase', function(error, result) {
          result = JSON.parse(result);
          assert.equal(result.url, 'http://localhost:8080/docs/Raven/Databases/Foobar');
          assert.equal(result.verb, 'put');
          return assert.equal(result.body, "{ Settings: { 'Raven/DataDir': '~/Tenants/FoobarDatabase' } }");
        });
      },
      'should create a database tenant with a default Raven/DataDir of "~/Tenants/{database name}" value if not provided': function(ds) {
        helpers.mockApiCalls(ds.defaultDatabase, 201);
        return ds.createDatabase('Foobar', function(error, result) {
          result = JSON.parse(result);
          assert.equal(result.url, 'http://localhost:8080/docs/Raven/Databases/Foobar');
          assert.equal(result.verb, 'put');
          return assert.equal(result.body, "{ Settings: { 'Raven/DataDir': '~/Tenants/Foobar' } }");
        });
      },
      'should be able to delete a database tenant': function(ds) {
        helpers.mockApiCalls(ds.defaultDatabase, 204);
        return ds.deleteDatabase('Foobar', function(error, result) {
          result = JSON.parse(result);
          assert.equal(result.url, 'http://localhost:8080/docs/Raven/Databases/Foobar');
          return assert.equal(result.verb, 'delete');
        });
      }
    }
  })["export"](module);

}).call(this);
