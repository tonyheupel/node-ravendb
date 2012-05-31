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

// Use http://localhost:8080 and Default database if no args passed in
// ravendb([datastoreUrl, databaseName])
var db = ravendb()

db.saveDocument('Users', { id: 'users/tony', firstName: 'Tony', lastName: 'Heupel'}, function(err, result) {
  if (err) console.error(err)
  else console.log(result)
})

db.getDocument('users/tony', function(err, result) {
  if (err) console.error(err)
  else console.log(result)
})

var otherdb = ravendb('http://some-remote-url.com', 'OtherDatabase')
otherdb.getDocument('things/foobar', function(err, result) {
	if (err) console.error(err)
	else console.log(result)
})
```