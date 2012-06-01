var Datastore = require('./datastore')

module.exports = ravendb = function(datastoreUrl, databaseName) {
  var r = new Datastore(datastoreUrl)

  if (!databaseName) databaseName = 'Default'
  
  return r.useDatabase(databaseName) // returning the db object that is "used" here
}




