_ = require 'underscore'

class Document
  @fromObject: (object) ->
    doc = new Document()
    _.extend(doc, object)
    doc.setMetadataValue("key", doc.id) if doc.id?
    doc


  constructor: ->
    @setMetadata({})


  setMetadata: (metadata) ->
    @["@metadata"] = metadata


  getMetadata: ->
    @["@metadata"]


  getMetadataValue: (key) ->
    @getMetadata()[key.toLowerCase()]


  setMetadataValue: (key, value) ->
    @getMetadata()[key.toLowerCase()] = value

  setMetadataValues: (object) ->
    @setMetadataValue(key, value) for key, value of object


module.exports = Document
