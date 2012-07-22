Datastore = require('./datastore')

module.exports = ravendb = (datastoreUrl, databaseName='Default') ->
  r = new Datastore(datastoreUrl)

  r.useDatabase(databaseName) # returning the db object that is "used" here
