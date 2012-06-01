// datastore.js
var Database = require('./database')

var Datastore = function(url) {
  if (!url) url = 'http://localhost:8080'

  this.url = url
  this.defaultDatabase = new Database(this, 'Default')
  this.databases = { 'Default':  this.defaultDatabase } // TODO: try to connect and populate?
}


Datastore.prototype.useDatabase = function(name) {
  if (!this.databases[name]) {
    // TODO: Connect and find it
    this.databases[name] = new Database(this, name)
  }

  this.currentDatabase = this.databases[name]

  return this.currentDatabase  
}


Datastore.prototype.useDefaultDatabase = function() {
  return this.useDatabase('Default')
}


Datastore.prototype.createDatabase = function(name, dataDirectory, cb) {
  // Put a document in the default database to add this tenant
  if (typeof dataDirectory === 'function') {
    cb = dataDirectory
    dataDirectory = '~/Tenants/' + name
  }

  this.defaultDatabase.saveDocument(null, { id: 'Raven/Databases/' + name, 'Settings': { 'Raven/DataDir': dataDirectory } }, function(error, result) {
    cb(error, result)
  })
}


Datastore.prototype.deleteDatabase = function(name, cb) {
  // Delete a document in the default database to add this tenant
  this.defaultDatabase.deleteDocument('Raven/Databases/' + name, function(error, result) {
    cb(error, result)
  })
}


module.exports = Datastore
