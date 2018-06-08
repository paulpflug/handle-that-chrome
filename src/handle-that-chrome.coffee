{processWork} = require "handle-that"

{launch} = require "chrome-launcher"
remoteInterface = require "chrome-remote-interface"

module.exports.launch = (options) => await launch port: options.port or 9222, chromeFlags: options.flags


module.exports = (work, options) => new Promise (resolve, reject) =>
  reject new Error "handle-that-chrome: no worker defined" unless (getItDone = options?.worker)
  [remaining, neededWorkers, work] = processWork(work, options)
  instance = null
  hadInstance = options.instance?
  finish = (e) =>
    console.error e.stack or e if e?
    finishTasks = []
    if instance and not hadInstance
      finishTasks.push instance.kill()
    finishTasks.push options.onFinish() if options?.onFinish?
    if finishTasks.length > 0
      await Promise.all(finishTasks)
    resolve()
  if (total = remaining) > 0
    current = 0
    port = options.port or 9222
    options.flags ?= [
      "--no-first-run"
      "--disable-translate"
      "--disable-background-networking"
      "--disable-extensions"
      "--disable-sync"
      "--metrics-recording-only"
      "--disable-default-apps"
      "--disable-gpu"
      "--headless"
    ]
    instance = options.instance ?= await launch port: port, chromeFlags: options.flags
    next = =>
      pieces = work.pop()
      if pieces
        for piece in pieces
          current++
          tab = await remoteInterface.New port: port
          rI = await remoteInterface target: tab, port: port
          try
            await getItDone(piece, rI, current, total)
          catch e
            if options.onError?
              options.onError(e)
            else
              console.error e
          await remoteInterface.Close(port: port, id:tab.id)
          remaining--

        if remaining > 0
          options.onProgress?(remaining)
          next().catch finish
        else
          finish()
      return null

    for i in [0...neededWorkers]
      next().catch finish
  else
    finish()