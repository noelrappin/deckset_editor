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

const contextMenu = new electron.remote.Menu()
contextMenu.append(
  new electron.remote.MenuItem({
    label: "Up",
    id: "context-up",
    click: () => {
      elmApp.ports.externalUpMenuClicked.send(null)
    }
  })
)

contextMenu.append(
  new electron.remote.MenuItem({
    label: "Down",
    id: "context-down",
    click: () => {
      elmApp.ports.externalDownMenuClicked.send(null)
    }
  })
)

contextMenu.append(new electron.remote.MenuItem({ type: "separator" }))

contextMenu.append(
  new electron.remote.MenuItem({
    label: "Edit",
    id: "context-edit",
    click: () => {
      elmApp.ports.externalEditMenuClicked.send(null)
    }
  })
)

contextMenu.append(
  new electron.remote.MenuItem({
    label: "Keep Changes",
    id: "context-keep",
    click: () => {
      elmApp.ports.externalKeepChangesMenuClicked.send(null)
    }
  })
)

contextMenu.append(
  new electron.remote.MenuItem({
    label: "Discard Changes",
    id: "context-discard",
    click: () => {
      elmApp.ports.externalDiscardChangesMenuClicked.send(null)
    }
  })
)

contextMenu.append(
  new electron.remote.MenuItem({
    label: "Delete",
    id: "context-delete",
    click: () => {
      elmApp.ports.externalDeleteMenuClicked.send(null)
    }
  })
)

contextMenu.append(
  new electron.remote.MenuItem({
    label: "Append",
    id: "context-append",
    click: () => {
      elmApp.ports.externalAppendMenuClicked.send(null)
    }
  })
)

elmApp.ports.selectedSlideInfo.subscribe(data => {
  if (data) {
    const editMode = data.mode === "edit"
    menu = electron.remote.Menu.getApplicationMenu()
    menu.getMenuItemById("up").enabled = true
    menu.getMenuItemById("down").enabled = true
    menu.getMenuItemById("delete").enabled = true
    menu.getMenuItemById("append").enabled = true
    menu.getMenuItemById("edit").enabled = !editMode
    menu.getMenuItemById("keep").enabled = editMode
    menu.getMenuItemById("discard").enabled = editMode
    if (data.contextMenu) {
      contextMenu.getMenuItemById("context-edit").visible = !editMode
      contextMenu.getMenuItemById("context-keep").visible = editMode
      contextMenu.getMenuItemById("context-discard").visible = editMode
      contextMenu.popup(currentWindow)
    }
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

electron.ipcRenderer.on("upMenuClicked", () => {
  elmApp.ports.externalUpMenuClicked.send(null)
})

electron.ipcRenderer.on("downMenuClicked", () => {
  elmApp.ports.externalDownMenuClicked.send(null)
})

electron.ipcRenderer.on("editMenuClicked", () => {
  elmApp.ports.externalEditMenuClicked.send(null)
})

electron.ipcRenderer.on("deleteMenuClicked", () => {
  elmApp.ports.externalDeleteMenuClicked.send(null)
})

electron.ipcRenderer.on("appendMenuClicked", () => {
  elmApp.ports.externalAppendMenuClicked.send(null)
})

electron.ipcRenderer.on("keepChangesMenuClicked", () => {
  elmApp.ports.externalKeepChangesMenuClicked.send(null)
})

electron.ipcRenderer.on("discardChangesMenuClicked", () => {
  elmApp.ports.externalDiscardChangesMenuClicked.send(null)
})

elmApp.ports.updateWindowTitle.subscribe(title => {
  currentWindow.setTitle(title)
})
