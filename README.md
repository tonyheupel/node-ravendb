ravendb
=======

A node library for RavenDB

Overview
--------
RavenDB is a "2nd generation NoSQL document store" that is built primarily for .NET.  RavenDB stores all of it's documents as JSON.
http://ravendb.net

Luckily, RavenDB has an excellent HTTP API, so this library was written against that API, Node.js is also natively JavaScript, so working with JSON documents in RavenDB seems a natrual fit.

Requirements
------------
* Node.js >= 0.8
* A RavenDB to access (inluding RavenHQ or NTLM-secured stores)

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

// Use NTLM security
var work = ravendb('http://internal-machine.workdomain.ad')
work.useNTLM('workdomain', 'tony', 'mypassword')
work.find('Users', { lastName: 'Heupel' }, function(err, result) {
  if (err) console.error(err)
  else console.log(result.length) // Returns an array of matching results
}

// Use RavenHQ
var hq = ravendb('https://1.ravenhq.com', 'tony-test')
hq.useRavenHq('0f2bb123-b5ad-4e92-9ec5-7026bff5b933') // Set API KEY
hq.getDocument('things/foobar', function(err, result) {
  if (err) console.error(err)
  else console.log(result)
})

```
