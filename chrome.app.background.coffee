noirAppWindow = undefined

createNoirAppWindow = ->
  options = {minWidth: 640, minHeight: 640}
  chrome.app.window.create "window.html", options, (appWindow) ->
    noirAppWindow = appWindow

chrome.app.runtime.onLaunched.addListener ->
  if noirAppWindow?
    noirAppWindow.focus()
  else
    createNoirAppWindow()
