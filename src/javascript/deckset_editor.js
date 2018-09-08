const electron = require("electron")
const fs = require("fs")

const currentWindow = electron.remote.getCurrentWindow()
const dialog = electron.remote.dialog

const elmApp = Elm.Main.init({ node: document.getElementById("container") })

function openFile() {
  dialog.showOpenDialog(fileNames => {
    if (typeof fileNames === "undefined") {
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
}

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
  openFile()
})

electron.ipcRenderer.on("openFileMenuClicked", () => {
  openFile()
})

electron.ipcRenderer.on("saveFileMenuClicked", () => {
  elmApp.ports.externalSaveMenuClicked.send(null)
})

electron.ipcRenderer.on("undoMenuClicked", () => {
  elmApp.ports.externalUndoMenuClicked.send(null)
})

electron.ipcRenderer.on("redoMenuClicked", () => {
  elmApp.ports.externalRedoMenuClicked.send(null)
})

elmApp.ports.updateWindowTitle.subscribe(title => {
  currentWindow.setTitle(title)
})
