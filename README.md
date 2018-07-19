# handle-that-chrome

handles pieces of work in chrome in parallel.
A small wrapper around `chrome-remote-interface`.

Features:
  - chunkifys the work in pieces to minimize overhead
  - shuffles the workpieces for a better load balance


### Install

```sh
npm install --save handle-that-chrome
```

### Usage

```js
handleThatChrome = require("handle-that-chrome")

// handleThatChrome(work:Array, options:Object)
handleThatChrome(["work1","work2"],{
  worker: (work, tab, currentIndex) => {
    // work is either ["work1"] or ["work2"]
    {DOM, CSS, Emulation, Page} = tab
    await Promise.all [DOM.enable(), CSS.enable(), Page.enable()]
    // ...
  }
}).then(=>
  // finished
)
```

#### Options
Name | type | default | description
---:| --- | ---| ---
worker | Function | - | (required) Callback called with an array of workpieces
shuffle | Boolean | true | should the work get shuffled
flatten | Boolean | true | the work array will be flattened
concurrency | Number | #CPUS | how many workers should get spawned
onProgress | Function | - | will be called on progress with the remaining work count
onError | Function | - | will be called on error in your worker function
onFinish | Function | - | will be called once all work is done
instance | Object | - | you can pass a existing chrome instance, this won't be closed onFinish
chrome | Object | {} | Launch options for chrome (https://github.com/GoogleChrome/chrome-launcher)
chrome.port | Number | 9222 | Port for the remote interface
chrome.chromeFlags | Array | see below | flags used to start chrome

```js
// default flags
[
  "--disable-gpu"
  "--headless"
]
// plus these set by chrome-launcher
// https://github.com/GoogleChrome/chrome-launcher/blob/master/src/flags.ts
```

#### Example with ora

```js
ora = require("ora")
handleThatChrome = require("handle-that-chrome")

spinner = ora(work.length + " workpieces remaining...").start()

handleThatChrome(work,{
  worker: => {},
  onProgress: (remaining) => { spinner.text = remaining  + " workpieces remaining..." },
  onFinish: => { spinner.succeed("finished") }
})
```

## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.
