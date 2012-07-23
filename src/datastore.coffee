# datastore.coffee
Database = require('./database')

class Datastore
  constructor: (@url='http://localhost:8080') ->
    @defaultDatabase = new Database(@, 'Default')
    @databases = { 'Default':  @defaultDatabase } # TODO: try to connect and populate?


  useDatabase: (name) ->
    # TODO: Connect and find it
    @databases[name] = new Database(@, name) unless @databases[name]?
    @currentDatabase = @databases[name]
    @currentDatabase


  useDefaultDatabase: ->
    @useDatabase 'Default'


  createDatabase: (name, dataDirectory, cb) ->
    # Put a document in the default database to add this tenant
    if typeof dataDirectory is 'function'
      cb = dataDirectory
      dataDirectory = "~/Tenants/#{name}"

    @defaultDatabase.saveDocument null, { id: "Raven/Databases/#{name}", 'Settings': { 'Raven/DataDir': dataDirectory } }, (error, result) ->
      cb(error, result)


  deleteDatabase: (name, cb) ->
    # Delete a document in the default database to add this tenant
    @defaultDatabase.deleteDocument "Raven/Databases/#{name}", (error, result) ->
      cb(error, result)



module.exports = Datastore
