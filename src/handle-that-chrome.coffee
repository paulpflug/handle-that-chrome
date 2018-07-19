{processWork} = require "handle-that"

chromeLauncher = require "chrome-launcher"
remoteInterface = require "chrome-remote-interface"

module.exports.launch = launch = (options={}) => 
  options.port ?= 9222
  options.chromeFlags ?= [
    "--disable-gpu"
    "--headless"
  ]
  await chromeLauncher.launch options

module.exports.chromeLauncher = chromeLauncher

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
    {port} = instance = options.instance ?= await launch options.chrome
    next = =>
      pieces = work.pop()
      if pieces?
        tab = await remoteInterface.New port: port
        rI = await remoteInterface target: tab, port: port 
        try
          await getItDone(pieces, rI, current += pieces.length)
        catch e
          if options.onError?
            options.onError(e)
          else
            console.error e
        await remoteInterface.Close(port: port, id:tab.id)
        remaining -= pieces.length
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