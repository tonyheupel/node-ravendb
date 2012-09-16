# database.coffee
request = require('request')


class Database
  @DOCUMENTS_BY_ENTITY_NAME_INDEX: 'Raven/DocumentsByEntityName'
  @DYNAMIC_INDEX: 'dynamic'

  constructor: (@datastore, @name) ->
    @authorization = null # Nothing by default
    @proxy = null         # Nothing by default

  getUrl: ->
    url = @datastore.url
    url += "/databases/#{@name}" unless @name is 'Default'
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

  setProxy: (proxyUrl) ->
    @proxy = proxyUrl


  getCollections: (cb) ->
    @apiGetCall @getTermsUrl(Database.DOCUMENTS_BY_ENTITY_NAME_INDEX, 'Tag'),  (error, response) ->
      if !error and response.statusCode is 200
        cb(null, JSON.parse(response.body)) if cb?
      else if cb?
        cb(error)

    return null


  saveDocument: (collection, doc, cb) ->
    # If not id provided, use POST to allow server-generated id
    # else, use PUT and use id in url
    op = @apiPostCall
    url = @getDocsUrl()

    if doc.id?
      op = @apiPutCall
      url = @getDocUrl(doc.id)
      delete doc.id # Don't add this as it's own property to the document...

    op.call @, url, doc, {'Raven-Entity-Name': collection}, (error, response) ->
      # TODO: skip this if no collection string passed in?

      if !error and response.statusCode is 201 # 201 - Created
        cb(null, response.body) if cb?
      else
        if cb?
          if error? then cb(error)
          else cb(new Error('Unable to create document: ' + response.statusCode + ' - ' + response.body))

    return null


  getDocument: (id, cb) ->
    url = @getDocUrl(id)
    @apiGetCall url, (error, response) ->
      if !error and response.statusCode is 200
        cb(null, JSON.parse(response.body))
      else
        cb(error)

    return null


  getDocuments: (ids, cb) ->
    url = @getQueriesUrl()

    @apiPostCall url, ids, (error, response) ->
      if !error and response.statusCode is 200
        cb(null, response.body) if cb?
      else
        if cb?
          if error? then cb(error)
          else cb(new Error('Unable to find documents: ' + response.statusCode + ' - ' + response.body))

    return null

  # PATCH - Update

  deleteDocument: (id, cb) ->
    url = @getDocUrl(id)
    # TODO: Still need to determine the cutOff and allowStale options - http://ravendb.net/docs/http-api/http-api-multi
    @apiDeleteCall url, (error, response) ->
      if !error and response.statusCode is 204  # 204 - No content
        cb(null, response.body) if cb?
      else
        if cb?
          if error? then cb(error)
          else cb(new Error('Unable to delete document: ' + response.statusCode + ' - ' + response.body))

    return null


  # Set-based updates

  deleteDocuments: (index, query, cb) ->
    url = @getBulkDocsIndexUrl(index, query)

    @apiDeleteCall url, (error, response) ->
      if !error and response.statusCode is 200
        cb(null, if response?.body?.length? > 0 then JSON.parse(response.body) else null) if cb?
      else
        if cb?
          if error? cb(error)
          else cb(new Error('Unable to delete documents: ' + response.statusCode + ' - ' + response.body))

    return null


  # Search

  find: (doc, start, count, cb) ->
    if typeof start is 'function'
      cb = start
      start = null
      count = null
    else if typeof count is 'function'
      cb = count
      count = null

    @dynamicQuery doc, start, count, (error, results) ->
      unless error
        results = JSON.parse(results.body)
        matches = if results?.Results? then results.Results else null

      cb(error, matches)

    return null


  getDocsInCollection: (collection, start, count, cb) ->
    if typeof start is 'function'
      cb = start
      start = null
      count = null
    else if typeof count is 'function'
      cb = count
      count = null

    @queryRavenDocumentsByEntityName collection, start, count, (error, results) ->
      results = JSON.parse(results.body) unless error?

      cb(error, if results?.Results? then results.Results else null)

    return null


  getDocumentCount: (collection, cb) ->
    # Passing in 0 and 0 for start and count simply returns the TotalResults and not the actual docs
    @queryRavenDocumentsByEntityName collection, 0, 0, (error, results) ->
      results = JSON.parse(results.body) unless error?
      cb(error, if results?.TotalResults? then results.TotalResults else null)

    return null


  getStats: (cb) ->
    @apiGetCall @getStatsUrl(), (error, results) ->
      stats = JSON.parse(results.body) unless error?
      cb(error, stats)

    return null


  # Indexes


  dynamicQuery: (doc, start, count, cb) ->
    @queryByIndex(Database.DYNAMIC_INDEX, doc, start, count, cb)


  queryRavenDocumentsByEntityName: (name, start, count, cb) ->
    search = if name? then { Tag:name } else null
    @queryByIndex(Database.DOCUMENTS_BY_ENTITY_NAME_INDEX, search, start, count, cb)


  queryByIndex: (index, query, start=0, count=25, cb) ->
    if typeof start is 'function'
      cb = start
      start = null
      count = null
    else if typeof count is 'function'
      cb = count
      count = null

    # if start and count are set to 0, you'll just get the TotalResults property
    # and no results

    url = "#{@getIndexUrl(index)}?start=#{start}&pageSize=#{count}&aggregation=None"
    url += "&query=#{@luceneQueryArgs(query)}" if query?

    @apiGetCall(url, cb)


  createIndex: (name, map, reduce, cb) ->
    # reduce is optional, so see if it is a callback
    if typeof reduce is 'function'
      cb = reduce
      reduce = null

    url = @getIndexUrl(name)
    index = { Map : map }

    if reduce? then index['Reduce'] = reduce

    @apiPutCall url, index, (error, response) ->
      if !error and response.statusCode is 201
        cb(null, if response?.body?.length? > 0 then JSON.parse(response.body) else null) if cb?
      else
        if cb?
          if error? then cb(error)
          else cb(new Error('Unable to create index: ' + response.statusCode + ' - ' + response.body))


  deleteIndex: (index, cb) ->
    url = @getIndexUrl(index)

    @apiDeleteCall url, (error, response) ->
      if !error and response.statusCode is 204  # 204 - No content
        cb(null, if response?.body?.length? > 0 then JSON.parse(response.body) else null) if cb?
      else
        if cb?
          if error? then cb(error)
          else cb(new Error('Unable to delete index: ' + response.statusCode + ' - ' + response.body))



  # Attachment methods
  saveAttachment: (docId, content, headers, cb) ->
    url = @getAttachmentUrl(docId)

    @apiPutCall url, content, headers, (error, response) ->
      if !error and response.statusCode is 201
        cb(null, if response?.body?.length? > 0 then JSON.parse(response.body) else null) if cb?
      else
        if cb?
          if error? then cb(error)
          else cb(new Error('Unable to save attachment: ' + response.statusCode + ' - ' + response.body))


  getAttachment: (id, cb) ->
    url = @getAttachmentUrl(id)
    @apiGetCall url, (error, response) ->
      if !error and response.statusCode is 200
        cb(null, response)
      else
        cb(error)


  deleteAttachment: (id, cb) ->
    url = @getAttachmentUrl(id)
    # TODO: Still need to determine the cutOff and allowStale options - http://ravendb.net/docs/http-api/http-api-multi
    @apiDeleteCall url, (error, response) ->
      if !error and response.statusCode is 204  # 204 - No content
        cb(null, response.body) if cb?
       else
        if cb?
          if error? then cb(error)
          else cb(new Error('Unable to delete attachment: ' + response.statusCode + ' - ' + response.body))



  # helper methods
  luceneQueryArgs: (query) ->
    return null unless query?

    pairs = []
    pairs.push "#{key}:#{value}" for key, value of query
    pairs.join '+'



  # Authorization providers
  useRavenHq: (apiKey, cb) ->
    database = @  # Look at using => in the request.get callbacks
    request.get { uri: database.getDocsUrl() }, (err, denied) -> # should be https://1.ravenhq.com/docs
      # denied.headers['oauth-source'] = https://oauth.ravenhq.com/ApiKeys/OAuth/AccessToken
      request.get { uri: denied.headers['oauth-source'], headers: { "Api-Key": apiKey } }, (err, oauth) ->
        database.setAuthorization("Bearer " + oauth.body)
        cb(err, oauth) if cb?



  # base API get calls
  apiGetCall: (url, headers, cb) ->
    if typeof headers is 'function'
      cb = headers
      headers = {}

    @apiCall 'get', url, null, headers, (error, response) ->
      cb(error, response)


  apiPutCall: (url, body, headers, cb) ->
    if typeof headers is 'function'
      cb = headers
      headers = {}

    @apiCall 'put', url, body, headers, (error, response) ->
      cb(error, response)
      # Maybe check for 201 - CREATED here?


  apiPostCall: (url, body, headers, cb) ->
    if typeof headers is 'function'
      cb = headers
      headers = {}

    @apiCall 'post', url, body, headers, cb  # Maybe check for UPDATED here?


  apiPatchCall: (url, body, headers, cb) ->
    if typeof headers is 'function'
      cb = headers
      headers = {}

    @apiCall 'patch', url, body, headers, cb  # Maybe check for success here?


  apiDeleteCall: (url, body, headers, cb) ->
    if typeof body is 'function'
      cb = body
      body = null
      headers = {}
    else if typeof headers is 'function'
      cb = headers
      headers = {}

    @apiCall 'delete', url, body, headers, cb  # Maybe check for DELETED here?


  apiCall: (verb, url, bodyOrReadableStream, headers, cb) ->
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

    headers.Authorization = @authorization if @authorization?

    req = { uri: url, headers: headers }
    req['proxy'] = @proxy if @proxy?
    # if passing in an object,
    #   see if it's a ReadableStream; if so, pipe it,
    #   else json so it sends application/json mime type
    # else set the body
    if bodyOrReadableStream?.readable?
      bodyOrReadableStream.pipe(op.call(request, req, cb))
      return

    req[if typeof bodyOrReadableStream is 'object' then 'json' else 'body'] = bodyOrReadableStream

    op.call(request, req, cb)

    return null



module.exports = Database
