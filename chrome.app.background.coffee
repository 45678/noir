NoirAppWindow = undefined

createNoirAppWindow = ->
  options = {minWidth: 640, minHeight: 640}
  chrome.app.window.create "window.html", options, (appWindow) ->
    NoirAppWindow = appWindow

chrome.app.runtime.onLaunched.addListener ->
  if NoirAppWindow?
    NoirAppWindow.focus()
  else
    createNoirAppWindow()
