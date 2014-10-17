noirAppWindow = undefined

createNoirAppWindow = ->
  options = {minWidth: 750, minHeight: 650}
  chrome.app.window.create "window.html", options, (appWindow) ->
    noirAppWindow = appWindow

chrome.app.runtime.onLaunched.addListener ->
  if noirAppWindow?
    noirAppWindow.focus()
  else
    createNoirAppWindow()
