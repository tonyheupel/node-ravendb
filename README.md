ravendb
=======

A node library for RavenDB

Overview
--------
RavenDB is a "2nd generation NoSQL document store" that is built primarily for .NET.  RavenDB stores all of it's documents as JSON.
http://ravendb.net

Luckily, RavenDB has an excellent HTTP API, so this library was written against that API,Node.js is also natively JavaScript, so working with JSON documents in RavenDB seems a natrual fit.

Requirements
------------
* Node.js >= 0.6
* A RavenDB to access

Usage
-----
```js
var ravendb = require('ravendb')

var datastore = ravendb.use('http://localhost:8080')
var db = datastore.defaultDb

db.saveDocument('Users', { id: 'users/tony', firstName: 'Tony', lastName: 'Heupel'}, function(err, result) {
  if (err) console.error(err)
  else console.log(result)
})

db.getDocument('users/tony', function(err, result) {
  if (err) console.error(err)
  else console.log(result)
})
```