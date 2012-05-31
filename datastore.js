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

module.exports = Datastore
