const { dialog } = require("electron").remote
const currentWindow = require("electron").remote.getCurrentWindow()
const fs = require("fs")
const elmApp = Elm.Main.init({ node: document.getElementById("container") })

elmApp.ports.savePresentationText.subscribe(data => {
  if (data.filename === "") {
    dialog.showSaveDialog(filename => {
      if (typeof filename === "undefined") {
        console.log("oops") // eslint-disable-line no-console
        return
      }
      fs.writeFile(filename, data.body, err => {
        if (err) {
          console.log(err) // eslint-disable-line no-console
          return
        }
        elmApp.ports.updateFileName.send(filename)
      })
    })
  } else {
    fs.writeFile(data.filename, data.body, err => {
      if (err) {
        console.log(err) // eslint-disable-line no-console
        return
      }
    })
  }
})

elmApp.ports.openFileDialog.subscribe(() => {
  dialog.showOpenDialog(fileNames => {
    if (typeof fileNames === "undefined") {
      console.log("No file selected") // eslint-disable-line no-console
      return
    }
    const filename = fileNames[0]
    fs.readFile(fileNames[0], "utf-8", (err, body) => {
      if (err) {
        alert(`An error ocurred reading the file :${err.message}`) // eslint-disable-line no-alert
        return
      }
      elmApp.ports.loadPresentationText.send({ filename, body })
    })
  })
})

elmApp.ports.updateWindowTitle.subscribe(title => {
  currentWindow.setTitle(title)
})
