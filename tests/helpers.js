// helpers.js
var helpers = {

  mockApiCalls: function(database, statusCode, returnObject) {
    if (!statusCode) statusCode = 200

    if (typeof statusCode === 'object') {
      returnObject = statusCode
      statusCode = 200
    }

    database.apiCall = function(verb, url, body, headers, cb) {
      if (typeof body === 'function') {
        cb = body
        body = null
        headers = null
      } else if (typeof headers === 'function') {
        cb = headers
        headers = null
      }

      if (!returnObject) returnObject = { statusCode: statusCode, body: { verb: verb, url: url, body: body, headers: headers } }

      cb(null, returnObject)
    }
  }

}

module.exports = helpers