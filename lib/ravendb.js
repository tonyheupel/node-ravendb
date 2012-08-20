(function() {
  var Datastore, ravendb;

  Datastore = require('./datastore');

  module.exports = ravendb = function(datastoreUrl, databaseName) {
    var r;
    if (databaseName == null) databaseName = 'Default';
    r = new Datastore(datastoreUrl);
    return r.useDatabase(databaseName);
  };

}).call(this);
