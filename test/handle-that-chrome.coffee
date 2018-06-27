{test, getTestID} = require "snapy"
handleThatChrome = require "../src/handle-that-chrome.coffee"

port = => 9223 + getTestID()

test (snap) =>
  works = []
  tabs = {}
  handleThatChrome([1,2,3],
    port: port()
    worker: (work, tab) =>
      works.push work[0]
      tabs[tab.target.id] = true
    onFinish: =>
      # should have piece 1,2,3
      snap obj: works.sort()
  ).then =>
    # should have 3 unique ids
    snap obj: Object.keys(tabs).length

test (snap) =>
  handleThatChrome [1], 
    port: port()
    # should catch test error
    onError: (e) => snap obj: e
    worker: => throw new Error "test error"

test (snap) =>
  handleThatChrome [1,2],
    port: port()
    worker: =>
    # should call onProgress after processing one piece
    onProgress: (piece) => snap obj: piece

test (snap) =>
  indices = []
  handleThatChrome [1,2],
    port: port()
    worker: (work, tab, index) => indices.push index
    # should have 1,2
    onFinish: => snap obj: indices.sort()