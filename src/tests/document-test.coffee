testino = require('testino')
assert = require('assert')
Document = require('../document')

basicObject = { id: "users/tony", name: "Tony Heupel" }
doc = Document.fromObject(basicObject)

module.exports = documentOperations = testino.createFixture('Document Operations')
documentOperations.tests =
  "Document.fromObject result should be the same object with some new properties": () ->
      assert.equal(doc.id, basicObject.id, "Document should have the same id property")
      assert.equal(doc.name, basicObject.name, "Document should have the same name property")
      assert(doc.getMetadata(), "An instance of Document should have a non-null metadata property")

  "Document.fromObject should add the 'id' property as the '@metadata/Key' property": () ->
      assert(doc.getMetadata(), "metadata should not be null")
      assert.equal(doc.getMetadataValue("Key"), doc.id)



console.log(module.exports.run()) if require.main is module
