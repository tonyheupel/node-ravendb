// database.js
var Database = function(datastore, name) {
  this.datastore = datastore
  this.name = name
}


Database.prototype.getUrl = function() {
  var url = this.datastore.url

  if (this.name != 'Default') {
    url += '/databases/' + this.name
  }

  return url
}


Database.prototype.getDocsUrl = function() { return this.getUrl() + '/docs' }
Database.prototype.getDocUrl = function(id) { return this.getDocsUrl() + '/' + id }
Database.prototype.getIndexesUrl = function() { return this.getUrl() + '/indexes' }
Database.prototype.getIndexUrl = function(index) { return this.getIndexesUrl() + '/' + index }
Database.prototype.getTermsUrl = function(index, field) {
  return this.getUrl() + '/terms/' + index + '?field=' + field
}


Database.prototype.getQueriesUrl = function() { return this.getUrl() + '/queries' }
Database.prototype.getBulkDocsUrl = function() { return this.getUrl() + '/bulk_docs' }
Database.prototype.getBulkDocsIndexUrl = function (index, query) {
  return this.getBulkDocsUrl() + '/' + index + '?query=' + this.luceneQueryArgs(query)
}


Database.prototype.getStatsUrl = function() { return this.getUrl() + '/stats' }
Database.DOCUMENTS_BY_ENTITY_NAME_INDEX = 'Raven/DocumentsByEntityName'
Database.DYNAMIC_INDEX = 'dynamic'


Database.prototype.getCollections = function(cb) {
  this.apiGetCall(this.getTermsUrl(Database.DOCUMENTS_BY_ENTITY_NAME_INDEX, 'Tag'), function (error, response) {
    if (!error && response.statusCode == 200) {
      if (cb) cb(null, JSON.parse(response.body))
    }
    else {
      if (cb) cb(error)
    }
  })
}


Database.prototype.saveDocument = function(collection, doc, cb) {
  // If not id provided, use POST to allow server-generated id
  // else, use PUT and use id in url
  var op = this.apiPostCall
    , url = this.getDocsUrl()

  if (doc.id) {
    op = this.apiPutCall
    url = this.getDocUrl(doc.id)
    delete doc.id // Don't add this as it's own property to the document...
  }

	op.call(this, url, doc, {'Raven-Entity-Name': collection}, // TODO: skip this if no collection string passed in?
                                                  // TODO: Add 'www-authenticate': 'NTLM' back into headers?
     function(error, response) {

    if (!error && response.statusCode == 201) { // 201 - Created
      if (cb) cb(null, response.body)
    }
    else {
      if (cb) {
        if (error) cb(error)
        else cb(new Error('Unable to create document: ' + response.statusCode + ' - ' + response.body))
      }
    }
	})
}


Database.prototype.getDocument = function(id, cb) {
  var url = this.getDocUrl(id)
  this.apiGetCall(url, function(error, response) {
    if (!error && response.statusCode == 200) cb(null, JSON.parse(response.body))
    else {
      cb(error)
    }
  })
}


Database.prototype.getDocuments = function(ids, cb) {
  var url = this.getQueriesUrl()

  this.apiPostCall(url, ids, function(error, response) {
    if (!error && response.statusCode == 200) {
      if (cb) cb(null, response.body)
    } else {
      if (cb) {
        if (error) cb(error)
        else cb(new Error('Unable to find documents: ' + response.statusCode + ' - ' + response.body))
      }
    }
  })
}


// PATCH - Update

Database.prototype.deleteDocument = function(id, cb) {
  var url = this.getDocUrl(id)
  // TODO: Still need to determine the cutOff and allowStale options - http://ravendb.net/docs/http-api/http-api-multi
  this.apiDeleteCall(url, function(error, response) {
    if (!error && response.statusCode == 204) {  // 204 - No content
      if (cb) cb(null, response.body)
    } else {
      if (cb) {
        if (error) cb(error)
          else cb(new Error('Unable to delete document: ' + response.statusCode + ' - ' + response.body))
      }
    }
  })
}


// Set-based updates

Database.prototype.deleteDocuments = function(index, query, cb) {
  var url = this.getBulkDocsIndexUrl(index, query)

  this.apiDeleteCall(url, function(error, response) {
    if (!error && response.statusCode == 200) {
      if (cb) cb(null, (response.body && response.body.length > 0) ? JSON.parse(response.body) : null)
    } else {
      if (cb) {
        if (error) cb(error)
          else cb(new Error('Unable to delete documents: ' + response.statusCode + ' - ' + response.body))
      }
    }
  })
}



// Search

Database.prototype.find = function(doc, start, count, cb) {
  if (typeof start === 'function') {
    cb = start
    start = null
    count = null
  } else if (typeof count === 'function') {
    cb = count
    count = null
  }

  this.dynamicQuery(doc, start, count, function(error, results) {
    var results = JSON.parse(results.body)
    var matches = results && results.Results ? results.Results : null
    cb(error, matches)
  })
}


Database.prototype.getDocsInCollection = function(collection, start, count, cb) {
  if (typeof start === 'function') {
    cb = start
    start = null
    count = null
  } else if (typeof count === 'function') {
    cb = count
    count = null
  }

  this.queryRavenDocumentsByEntityName(collection, start, count, function(error, results) {
    var results = JSON.parse(results.body)
    cb(error, results && results.Results ? results.Results : null)
  })
}


Database.prototype.getDocumentCount = function(collection, cb) {
  // Passing in 0 and 0 for start and count simply returns the TotalResults and not the actual docs
  this.queryRavenDocumentsByEntityName(collection, 0, 0, function(error, results) {
    var results = JSON.parse(results.body)
    cb(error, results && results.TotalResults ? results.TotalResults : null)
  })
}


Database.prototype.getStats = function(cb) {
  this.apiGetCall(this.getStatsUrl(), function(error, results) {
    var stats = JSON.parse(results.body)
    cb(error, stats)
  })
}



// Indexes


Database.prototype.dynamicQuery = function(doc, start, count, cb) {
  this.queryByIndex(Database.DYNAMIC_INDEX, doc, start, count, cb)
}


Database.prototype.queryRavenDocumentsByEntityName = function(name, start, count, cb) {
  this.queryByIndex(Database.DOCUMENTS_BY_ENTITY_NAME_INDEX, name ? { Tag:name } : null, start, count, cb)
}


Database.prototype.queryByIndex = function(index, query, start, count, cb) {
  if (typeof start === 'function') {
    cb = start
    start = null
    count = null
  } else if (typeof count === 'function') {
    cb = count
    count = null
  }

  if (typeof start === 'undefined' || start === null) start = 0
  if (typeof count === 'undefined' || count === null) count = 25  // Arbitrary count...
  // if start and count are set to 0, you'll just get the TotalResults property
  // and no results

  var url = this.getIndexUrl(index) + '?start=' + start + '&pageSize=' + count + '&aggregation=None&query='
  url += this.luceneQueryArgs(query)

  this.apiGetCall(url, cb)
}


Database.prototype.createIndex = function(name, map, reduce, cb) {
  // reduce is optional, so see if it is a callback function
  if (typeof reduce === 'function') {
    cb = reduce
    reduce = null
  }

  var url = this.getIndexUrl(name)
  var index = { Map : map }
  if (reduce) index['Reduce'] = reduce

  this.apiPutCall(url, index, function(error, response) {
    if (!error && response.statusCode == 201) {
      if (cb) cb(null, response.body && response.body.length > 0 ? JSON.parse(response.body) : null)
    } else {
      if (cb) {
        if (error) cb(error)
        else cb(new Error('Unable to create index: ' + response.statusCode + ' - ' + response.body))
      }
    }
  })
}


Database.prototype.deleteIndex = function(index, cb) {
  var url = this.getIndexUrl(index)

  this.apiDeleteCall(url, function(error, response) {
    if (!error && response.statusCode == 204) {  // 204 - No content
      if (cb) cb(null, (response.body && response.body.length > 0) ? JSON.parse(response.body) : null)
    } else {
      if (cb) {
        if (error) cb(error)
          else cb(new Error('Unable to delete index: ' + response.statusCode + ' - ' + response.body))
      }
    }
  })
}


// helper methods
Database.prototype.luceneQueryArgs = function(query) {
  var qs = ''
    , afterFirst = false

  for (field in query) {
    if (afterFirst) qs += '+'

    qs += field + ':' + query[field]

    afterFirst = true
  }

  return qs
}


// base API get calls
Database.prototype.apiGetCall = function(url, headers, cb) {
  if (typeof headers == 'function') {
    cb = headers
    headers = null
  }

  this.apiCall('get', url, null, headers, function(error, response) {
    cb(error, response)
  })
}


Database.prototype.apiPutCall = function(url, body, headers, cb) {
  if (typeof headers == 'function') {
    cb = headers
    headers = null
  }

  this.apiCall('put', url, body, headers, function(error, response) {
    cb(error, response)
  }) // Maybe check for 201 - CREATED here?
}


Database.prototype.apiPostCall = function(url, body, headers, cb) {
  if (typeof headers == 'function') {
    cb = headers
    headers = null
  }

	this.apiCall('post', url, body, headers, cb) // Maybe check for UPDATED here?
}


Database.prototype.apiPatchCall = function(url, body, headers, cb) {
  if (typeof headers == 'function') {
    cb = headers
    headers = null
  }

	this.apiCall('patch', url, body, headers, cb) // Maybe check for success here?
}


Database.prototype.apiDeleteCall = function(url, body, headers, cb) {
  if (typeof body == 'function') {
    cb = body
    body = null
    headers = null
  } else if (typeof headers == 'function') {
    cb = headers
    headers = null
  }

	this.apiCall('delete', url, body, headers, cb) // Maybe check for DELETED here?
}


var request = require('request')

Database.prototype.apiCall = function(verb, url, body, headers, cb) {
  var verb = verb.toLowerCase()
  var op

  switch(verb) {
    case 'get':
      op = request.get
      break
    case 'put':          // create new when client can't predict id
      op = request.put
      break
    case 'post':         // override definition of resource with id
      op = request.post
      break
    case 'patch':        // update part of an existing resource
      // op = request.patch
      throw new Error('request module does not yet support patch verb')
      break
    case 'delete':       // delete resource
      op = request.del
      break
    default:
      throw new Error('No operation matched the verb "' + verb +'"')
      break
  }

  op.call(request, { uri: url, json: body, headers: headers}, cb)
}


module.exports = Database
