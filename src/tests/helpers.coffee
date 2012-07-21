# helpers.js

util = require('util')
helpers =
  mockApiCalls: (database, statusCode=200, returnObject) ->

    if typeof statusCode == 'object'
      returnObject = statusCode
      statusCode = 200

    database.apiCall = (verb, url, body, headers, cb) ->
      if typeof body == 'function'
        cb = body
        body = null
        headers = null
      else if typeof headers == 'function'
        cb = headers
        headers = null

      unless returnObject?
        returnObject =
          statusCode: statusCode
          body: "{ \"verb\": \"#{verb}\", \"url\": \"#{url}\", \"body\": \"#{if typeof body == 'object' then util.inspect(body) else body}\", \"headers\": \"#{util.inspect(headers)}\"}"

      cb(null, returnObject)


module.exports = helpers
