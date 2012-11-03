request = require 'request'
_ = require 'underscore'

class Api
  @IGNORE_HEADERS = [
    # Raven internal headers
    "Raven-Server-Build",
    "Non-Authoritative-Information",
    "Raven-Timer-Request",
    "Raven-Authenticated-User",

    # COTS
    "Access-Control-Allow-Origin",
    "Access-Control-Max-Age",
    "Access-Control-Allow-Methods",
    "Access-Control-Request-Headers",
    "Access-Control-Allow-Headers",

    # Proxy
    "Reverse-Via",
    "Persistent-Auth",
    "Allow",
    "Content-Disposition",
    "Content-Encoding",
    "Content-Language",
    "Content-Location",
    "Content-MD5",
    "Content-Range",
    "Expires",
    # ignoring this header, we handle this internally
    "Last-Modified",
    # Ignoring this header, since it may
    # very well change due to things like encoding,
    # adding metadata, etc
    "Content-Length",
    # Special things to ignore
    "Keep-Alive",
    "X-Powered-By",
    "X-AspNet-Version",
    "X-Requested-With",
    "X-SourceFiles",
    # Request headers
    "Accept-Charset",
    "Accept-Encoding",
    "Accept",
    "Accept-Language",
    "Authorization",
    "Cookie",
    "Expect",
    "From",
    "Host",
    "If-Match",
    "If-Modified-Since",
    "If-None-Match",
    "If-Range",
    "If-Unmodified-Since",
    "Max-Forwards",
    "Referer",
    "TE",
    "User-Agent",
    # Response headers
    "Accept-Ranges",
    "Age",
    "Allow",
    "ETag",
    "Location",
    "Retry-After",
    "Server",
    "Set-Cookie2",
    "Set-Cookie",
    "Vary",
    "Www-Authenticate",
    # General
    "Cache-Control",
    "Connection",
    "Date",
    "Pragma",
    "Trailer",
    "Transfer-Encoding",
    "Upgrade",
    "Via",
    "Warning"
  ]


  constructor: (@datastoreUrl, @databaseName="Default") ->
    @authorization = null
    @proxy = null


  getUrl: ->
    url = @datastoreUrl
    url += "/databases/#{@databaseName}" unless @databaseName is 'Default'
    url

  getDocsUrl: ->
    "#{@getUrl()}/docs"

  getDocUrl: (id) ->
    "#{@getDocsUrl()}/#{id}"

  getIndexesUrl: ->
    "#{@getUrl()}/indexes"

  getIndexUrl: (index) ->
    "#{@getIndexesUrl()}/#{index}"

  getTermsUrl: (index, field) ->
    "#{@getUrl()}/terms/#{index}?field=#{field}"

  getStaticUrl: ->
    "#{@getUrl()}/static"

  getAttachmentUrl: (id) ->
    "#{@getStaticUrl()}/#{id}"

  getQueriesUrl: ->
    "#{@getUrl()}/queries"

  getBulkDocsUrl: ->
    "#{@getUrl()}/bulk_docs"

  getBulkDocsIndexUrl:  (index, query) ->
    "#{@getBulkDocsUrl()}/#{index}?query=#{@luceneQueryArgs(query)}"

  getStatsUrl: ->
    "#{@getUrl()}/stats"

  setAuthorization: (authValue) ->
    @authorization = authValue

  setBasicAuthorization: (username, password) ->
    user_pwd = new Buffer("#{username}:#{password}").toString('base64')
    @setAuthorization "Basic #{user_pwd}"

  setProxy: (proxyUrl) ->
    @proxy = proxyUrl


  getIgnoreHeaders: ->
    Api.IGNORE_HEADERS

  getIgnoreHeadersLowerCase: ->
    unless @ignoreHeadersLowerCase?
      @ignoreHeadersLowerCase = _.map @getIgnoreHeaders(), (header) ->
        header.toLowerCase()

    @ignoreHeadersLowerCase


  filterHeaders: (response) ->
    response.headers = _.omit response.headers, @getIgnoreHeadersLowerCase()
    delete response.headers[key] if key.substring(0, 4) is "temp" for key, value of response.headers

    return

  # base API calls
  get: (url, headers, cb) ->
    if typeof headers is 'function'
      cb = headers
      headers = {}

    @makeReqeust 'get', url, null, headers, (error, response) ->
      cb(error, response)


  put: (url, body, headers, cb) ->
    if typeof headers is 'function'
      cb = headers
      headers = {}

    @makeReqeust 'put', url, body, headers, (error, response) ->
      cb(error, response)
      # Maybe check for 201 - CREATED here?


  post: (url, body, headers, cb) ->
    if typeof headers is 'function'
      cb = headers
      headers = {}

    @makeRequest 'post', url, body, headers, cb  # Maybe check for UPDATED here?


  patch: (url, body, headers, cb) ->
    if typeof headers is 'function'
      cb = headers
      headers = {}

    @makeRequest 'patch', url, body, headers, cb  # Maybe check for success here?


  delete: (url, body, headers, cb) ->
    if typeof body is 'function'
      cb = body
      body = null
      headers = {}
    else if typeof headers is 'function'
      cb = headers
      headers = {}

    @makeRequest 'delete', url, body, headers, cb  # Maybe check for DELETED here?




  makeReqeust: (verb, url, bodyOrReadableStream, headers, cb) ->
    verb = verb.toLowerCase()

    switch verb
      when 'get' then op = request.get
      when 'put' then op = request.put    # create new when client can't predict id
      when 'post' then op = request.post  # override definition of resource with id
      when 'delete' then op = request.del # delete resource
      when 'patch'
        throw new Error('request module does not yet support patch verb') # update part of an existing resource
      else
        throw new Error('No operation matched the verb "' + verb +'"')

    requestHeaders = _.clone(headers) # Don't want to effect the object passed in by reference
    requestHeaders.Authorization = @authorization if @authorization?

    req = { uri: url, headers: requestHeaders }
    req['proxy'] = @proxy if @proxy?
    # if passing in an object,
    #   see if it's a ReadableStream; if so, pipe it,
    #   else json so it sends application/json mime type
    # else set the body
    if bodyOrReadableStream?

      if bodyOrReadableStream.readable?
        bodyOrReadableStream.pipe(op.call(request, req, cb))
        return

      if typeof bodyOrReadableStream is 'object'
        unless req.headers['content-type']?
          req.headers['content-type'] = 'application/json; charset=utf-8'

        req.body = JSON.stringify(bodyOrReadableStream)
      else
        req.body = bodyOrReadableStream

    op.call request, req, (error, response) =>
      if error?
        console.log "I think there's errors: #{JSON.stringify(error)}"
        cb(error, response)
        return

      @filterHeaders(response)
      cb(error, response)

    return


module.exports = Api
