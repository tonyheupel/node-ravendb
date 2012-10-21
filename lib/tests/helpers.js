(function() {
  var helpers, util;

  util = require('util');

  helpers = {
    mockApiCalls: function(database, statusCode, returnObject) {
      if (statusCode == null) statusCode = 200;
      if (typeof statusCode === 'object') {
        returnObject = statusCode;
        statusCode = 200;
      }
      return database.apiCall = function(verb, url, body, headers, cb) {
        if (typeof body === 'function') {
          cb = body;
          body = null;
          headers = null;
        } else if (typeof headers === 'function') {
          cb = headers;
          headers = null;
        }
        if (returnObject == null) {
          returnObject = {
            statusCode: statusCode,
            body: "{ \"verb\": \"" + verb + "\", \"url\": \"" + url + "\", \"body\": \"" + (typeof body === 'object' ? util.inspect(body) : body) + "\", \"headers\": \"" + (util.inspect(headers)) + "\"}"
          };
        }
        return cb(null, returnObject);
      };
    }
  };

  module.exports = helpers;

}).call(this);
