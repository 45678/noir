Function.delay = (amount, callback) -> setTimeout(callback, amount)
Backbone = require "backbone"
d3 = require "d3"
miniLockLib = require "miniLockLib"
moment = require "moment"

miniLockLib.Blob = {}
miniLockLib.Blob.hasMiniLockFileFormat = (blob, respond) ->
  if blob is undefined
    throw "miniLockLib.Blob.hasMiniLockFileFormat received undefined blob."
  if blob.slice.constructor isnt Function
    throw "miniLockLib.Blob.hasMiniLockFileFormat received unacceptable blob."
  reader = new FileReader
  reader.onload = -> respond reader.result is "miniLock"
  reader.onerror = -> respond no
  reader.readAsText blob.slice(0, 8)
  return undefined

window.operations = new Backbone.Collection
window.files = new Backbone.Collection
window.trash = new Backbone.Collection
window.links = new Backbone.Collection
window.force = d3.layout.force()

if (serializedKeys = sessionStorage.getItem "keys") and (started = sessionStorage.getItem "started")
  console.info "Resuming session that started #{moment(Number started).fromNow()}."
  window.keys = {publicKey: (new Uint8Array 32), secretKey: (new Uint8Array 32)}
  parsedKeys = JSON.parse serializedKeys
  window.keys.publicKey[index] = value for index, value of parsedKeys.publicKey
  window.keys.secretKey[index] = value for index, value of parsedKeys.secretKey
  window.keys.address = parsedKeys.address
else
  console.info "Starting new session."
  sessionStorage.setItem "started", Date.now()

document.addEventListener "DOMContentLoaded", (event) ->
  Function.delay 1, -> document.body.classList.add "ready"
  d3.select(document.body).append("svg").attr("id", "view")
  insertKeys() if window.keys?
  insertAddButton()
  insertTrashButton()
  render()
  files.on add: render, remove: render
  window.onresize = render
  if window.keys
    makeREADME()
  else
    Function.delay 1, makeKeys

render = ->
  render.cache.files = files.toArray()
  render.cache.links = links.toJSON()
  d3.select("#view").attr width: window.innerWidth, height: window.innerHeight
  force.size([window.innerWidth, window.innerHeight])
  force.gravity 0.002
  force.charge -75
  force.linkDistance 150
  force.nodes(render.cache.files)
  force.links(render.cache.links)
  force.start()
  renderLinks()
  renderNodes()
  renderKeys()
  renderAddButton()
  renderTrashButton()

render.cache = {}

insertKeys = ->
  group = d3.select("#view").append("g").attr("id", "keys")
  icon = group.append -> iconGraphic("miniLockID")
  icon.attr width: 20, height: 20, y: -40+1
  group.append("text").attr(class: "address")
  group.append("text").attr(class: "miniLockID")

renderKeys = ->
  d3.select("#keys").attr
    transform: "translate(0, #{window.innerHeight})"
  address = d3.select("#keys text.address").attr
    x: 20
    y: -22
  address.text ->
    "#{keys.address}"
  miniLockIDicon = d3.select("#keys svg.miniLockID.icon").attr
    x: address.node().getBBox().width + 35
  miniLockID = d3.select("#keys text.miniLockID").attr
    x: address.node().getBBox().width + 35 + 24
    y: -22
  miniLockID.text ->
    "ID #{miniLockLib.ID.encode(keys.publicKey)}"


insertAddButton = ->
  group = d3.select("#view").append("g").attr("id", "add")
  group.append("circle").attr("r", 32)
  group.append -> iconGraphic("add")

renderAddButton = ->
  d3.select("#add").attr
    transform: "translate(32, 32)"
  d3.select("#add svg.icon").attr
    width: 32
    height: 32
    x: -16
    y: -16

insertTrashButton = ->
  group = d3.select("#view").append("g").attr("id", "trash")
  group.append("circle").attr("r", 32)
  group.append -> iconGraphic("trash")

renderTrashButton = ->
  d3.select("#trash").attr
    transform: "translate(#{innerWidth-32}, #{innerHeight-32})"
  d3.select("#trash svg.icon").attr
    width: 32
    height: 32
    x: -16
    y: -16

renderLinks = ->
  link = d3.select("#view").selectAll("line.link").data(render.cache.links)
  link.enter().append("line").attr class: "link"
  link.style "stroke-width", (link) -> Math.sqrt(link.source.weight+link.target.weight)

renderNodes = ->
  node = d3.select("#view").selectAll("g.node").data(render.cache.files)
  group = node.enter().append("g").attr
    class: "file node"
    id: (file) -> file.cid
  group.append("circle").call(force.drag).attr
    class: "handle"
    r: 66
  group.append (file) ->
    mediaTypeIconGraphic file.get("data").type
  group.append("text").attr
    class: "name"
  group.append("text").attr
    class: "type"
  group.append("text").attr
    class: "size"
  group.append("text").attr
    class: "time"
  group.append("circle").attr
    class: "size"
    r: (d) -> Math.max 1, Math.sqrt(d.get("data").size / 409600)

force.on "tick", ->
  view = d3.select("#view")
  link = view.selectAll("line.link").data(render.cache.links)
  link.attr "x1", (d) -> d.source.x
  link.attr "y1", (d) -> d.source.y
  link.attr "x2", (d) -> d.target.x
  link.attr "y2", (d) -> d.target.y
  view.selectAll("g.file.node").data(render.cache.files).attr
    x: (d) -> d.x
    y: (d) -> d.y
  view.selectAll("g.file.node svg.icon").data(render.cache.files).attr
    x: (file) -> file.x - 56/2
    y: (file) -> file.y - 64 - 50
    height: 64
    width: 56
  view.selectAll("g.file.node circle.handle").data(render.cache.files).attr
    transform: (d) -> "translate(#{d.x}, #{d.y-66})"
    r: 66
  view.selectAll("g.file.node circle.size").data(render.cache.files).attr
    "transform": (d) -> "translate(#{d.x}, #{d.y})"
  nameLabel = view.selectAll("g.file.node text.name").data(render.cache.files).attr
    transform: (d) -> "translate(#{d.x}, #{d.y-30-2})"
  nameLabel.text (file) ->
    file.get("name")
  timeLabel = view.selectAll("g.file.node text.time").data(render.cache.files).attr
    class: (file) -> if file.get("data").lastModified then "time" else "undefined time"
    transform: (file) -> "translate(#{file.x}, #{file.y-20})"
  timeLabel.text (file) ->
    if file.get("data")?.lastModified
      moment(file.get("data").lastModified).fromNow()
    else
      "undefined"
  sizeLabel = view.selectAll("g.file.node text.size").data(render.cache.files).attr
    transform: (d) -> "translate(#{d.x}, #{d.y-10})"
  sizeLabel.text (file) ->
    formatSizeOfFile file.get("data").size
  mediaTypeLabel = view.selectAll("g.file.node text.type").data(render.cache.files).attr
    class: (file) -> if file.get("data").type then "type" else "undefined type"
    transform: (file) -> "translate(#{file.x}, #{file.y})"
  mediaTypeLabel.text (file) ->
    file.get("data").type or 'undefined'

makeKeys = ->
  secretPhrase = "this is a phrase that i am using in the demo"
  emailAddress = "undefined@45678.link"
  console.info "Making key pair..."
  operation = operations.add miniLockLib.makeKeyPair secretPhrase, emailAddress, (error, keys) ->
    throw error if error
    operations.remove(operation)
    keys.address = emailAddress
    sessionStorage.setItem "keys", JSON.stringify keys
    window.keys = keys
    insertKeys()
    makeREADME()

document.addEventListener "change", (event) ->
  if event.target.type is "file"
    for file in event.target.files
      added = files.add {data: file, name: file.name}
      added.x = added.px = innerWidth / 3
      added.y = added.py = innerHeight / 3
      miniLockLib.Blob.hasMiniLockFileFormat file, (blobHasMiniLockFileFormat) ->
        if blobHasMiniLockFileFormat
          Function.delay 333, -> decrypt(added)
        else
          Function.delay 333, -> encrypt(added)

document.addEventListener "mousedown", (event) ->
  parentNode = event.target.parentNode
  switch
    when parentNode.classList.contains("file", "node")
      mouseDownOnFileNode(event)
    when parentNode.id is "trash"
      console.info "Open trash"
    when parentNode.id is "add"
      mouseDownOnAddButton(event)

mouseDownOnAddButton = (event) ->
  event.preventDefault()
  document.querySelector("input[type=file]").click()

mouseDownOnFileNode = (event) ->
  file = files.get event.target.parentNode.id
  event.target.addEventListener "mousemove", abortIfMouseIsMoved = ->
    removeEventListeners()
  event.target.addEventListener "mouseup", downloadWhenMouseIsUp = ->
    removeEventListeners()
    download(file)
  removeEventListeners = ->
    event.target.removeEventListener "mouseup", downloadWhenMouseIsUp
    event.target.removeEventListener "mousemove", abortIfMouseIsMoved

# Save a copy of the file to the local file system.
download = (file) ->
  linkToSaveFile = document.body.appendChild(document.createElement("a"))
  linkToSaveFile.href = window.URL.createObjectURL(file.get("data"))
  linkToSaveFile.download = file.get("name")
  linkToSaveFile.click()
  linkToSaveFile.remove()

# Accept files dropped on the window.
document.addEventListener "dragover", (event) ->
  event.preventDefault()
document.addEventListener "dragleave", (event) ->
  event.preventDefault()
document.addEventListener "drop", (event) ->
  event.preventDefault()
  for blob in event.dataTransfer.files
    # if blob isnt event.dataTransfer.files[0]
    #   links.add {source: files.length-1, target: files.length}
    added = files.add {data: blob, name: blob.name}
    added.x = added.px = event.x
    added.y = added.py = event.y
    miniLockLib.Blob.hasMiniLockFileFormat blob, (blobHasMiniLockFileFormat) ->
      if blobHasMiniLockFileFormat
        Function.delay 333, -> decrypt(added)
      else
        Function.delay 333, -> encrypt(added)

# Encrypt a file.
encrypt = (file) ->
  encryptOperation = operations.add miniLockLib.encrypt
    data: file.get("data")
    name: file.get("name")
    keys: window.keys
    miniLockIDs: [miniLockLib.ID.encode(window.keys.publicKey)]
    callback: (error, encrypted) ->
      throw error if error
      operations.remove(encryptOperation)
      encrypted.name = "#{file.get("name").split(".")[0]}.minilock"
      encrypted.data.lastModified = Date.now()
      links.add {source: files.indexOf(file), target: files.length}
      encryptedFile = files.add encrypted
      encryptedFile.x = encryptedFile.px = file.x + 32
      encryptedFile.y = encryptedFile.py = file.y + 32

# Decrypt a file.
decrypt = (file) ->
  decryptOperation = operations.add miniLockLib.decrypt
    data: file.get("data")
    keys: window.keys
    callback: (error, decrypted) ->
      throw error if error
      operations.remove(decryptOperation)
      decrypted.data.lastModified = Date.now()
      links.add {source: files.indexOf(file), target: files.length}
      decryptedFile = files.add decrypted
      decryptedFile.x = decryptedFile.px = file.x + 32
      decryptedFile.y = decryptedFile.py = file.y + 32

# Format file size as string.
formatSizeOfFile = (bytes) ->
	KB = bytes / 1024
	MB = KB	/ 1024
	GB = MB	/ 1024
	if (bytes < 1024)
		return bytes + " bytes"
	if (KB < 1024)
		return Math.round(bytes / 1024) + " KB"
	if (MB < 1024)
		return (Math.round(MB * 10) / 10) + " MB"

# Get icon graphic by name.
iconGraphic = (name) ->
  document.body.querySelector("body > svg.#{name}.icon").cloneNode(true)

# Get icon for specified media type.
mediaTypeIconGraphic = (type="application/octet-stream", name="undefined") ->
  # console.info "iconGraphic", type
  if type in ["application/minilock"] then name = "minilock"
  if type.match("text/") then name = "text"
  if type.match("image/") then name = "image"
  if type is "application/zip" then name = "zip"
  if type is "application/pdf" then name = "pdf"
  document.body.querySelector("body > svg.#{name}.icon").cloneNode(true)

makeREADME = ->
  text = """
    Noir is a miniLock encryption workspace.

    Drop files on the window to add them to the workspace.

    Or click the + button to select files from with the operating system file chooser dialog box.

    Click any file in the workspace to save a copy.

    Click the camera button to make a photograph in the workspace.

    Drag a file to the trash to remove it from the workspace.

    Close the window or quit to end your session.

    • Somehow define permits.
    • Somehow define keys.
  """
  README = new Blob [text], type: "text/plain"
  encryptOperation = operations.add miniLockLib.encrypt
    data: README
    name: "Readme.txt"
    keys: window.keys
    miniLockIDs: [miniLockLib.ID.encode(keys.publicKey)]
    callback: (error, encrypted) ->
      throw error if error
      operations.remove(encryptOperation)
      encrypted.data.lastModified = Date.now()
      encrypted.name = "README.minilock"
      encryptedModel = files.add encrypted
      encryptedModel.x = encryptedModel.px = window.innerWidth / 2
      encryptedModel.y = encryptedModel.py = window.innerHeight / 2
      Function.delay 333, ->
        decryptOperation = operations.add miniLockLib.decrypt
          data: encrypted.data
          keys: window.keys
          callback: (error, decrypted) ->
            throw error if error
            operations.remove(decryptOperation)
            decrypted.data.lastModified = Date.now()
            links.add {source: files.indexOf(encryptedModel), target: files.length}
            decryptedModel = files.add decrypted
            decryptedModel.y = decryptedModel.py = encryptedModel.y + 33
            decryptedModel.x = decryptedModel.px = encryptedModel.x + 33
