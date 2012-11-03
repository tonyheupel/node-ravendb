vows = require('vows')
assert = require('assert')
#helpers = require('./helpers')
Document = require('../document')

ravendb = require('../ravendb')

vows.describe('Document Operations').addBatch
  'An instance of a Document object':
    topic: new Document()
    'should get a new object with prototype of Document': (doc) ->
      doc.__proto__ = Document

  'The Document.fromObject function':
    topic: Document.fromObject({ id: "users/tony", name: "Tony Heupel" })
    'should be the same object with new properties': (doc) ->
      assert.equal(doc.id, "users/tony")
      assert.equal(doc.name, "Tony Heupel")
      assert(doc.getMetadata(), "An instance of Document should have a non-null metadata property")

    'should add the id proeprty as the @metadata/Key property': (doc) ->
      assert(doc.getMetadata(), "metadata should not be null")
      assert.equal(doc.getMetadataValue("Key"), doc.id)



.export(module)
