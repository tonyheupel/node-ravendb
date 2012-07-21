Datastore = require('./datastore')

module.exports = ravendb = (datastoreUrl, databaseName) ->
  r = new Datastore(datastoreUrl)

  databaseName = 'Default' unless databaseName?

  r.useDatabase(databaseName) # returning the db object that is "used" here

