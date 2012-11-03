Datastore = require('./datastore')


ravendb = (datastoreUrl, databaseName='Default') ->
  ds = new Datastore(datastoreUrl)
  ds.useDatabase(databaseName) # return the database being used


# Expose the classes as members of the ravendb function so
# other modules can tweak them :-)
ravendb.Datastore = Datastore
ravendb.Database = require('./database')
ravendb.Document = require('./document')


module.exports = ravendb
