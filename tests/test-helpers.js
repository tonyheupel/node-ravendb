// test-helpers.js
var helpers = {

  mockApiCalls: function(database, statusCode) {
    if (!statusCode) statusCode = 200
    database.apiCall = function(verb, url, body, headers, cb) {
      if (typeof body === 'function') {
        cb = body
        body = null
        headers = null
      } else if (typeof headers === 'function') {
        cb = headers
        headers = null
      }

      cb(null, { statusCode: statusCode, body: JSON.stringify({ verb: verb, url: url, body: body, headers: headers }) })
    }
  }

}

module.exports = helpers