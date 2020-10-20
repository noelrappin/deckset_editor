const electron = require("electron")
const app = electron.app

const BrowserWindow = electron.BrowserWindow
const Menu = electron.Menu

let mainWindow

app.on("ready", createWindow)

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1024,
    height: 768,
    webPreferences: {
      nodeIntegration: true,
      enableRemoteModule: true,
      // preload: path.join(app.getAppPath(), 'preload.js')
    },
  })
  mainWindow.loadURL(`file://${__dirname}/src/static/index.html`)
  // mainWindow.webContents.openDevTools()
  mainWindow.on("closed", () => {
    mainWindow = null
  })

  const menu = Menu.buildFromTemplate([
    {
      label: app.getName(),
      submenu: [
        { role: "about" },
        { type: "separator" },
        { role: "services", submenu: [] },
        { type: "separator" },
        { role: "hide" },
        { role: "hideothers" },
        { role: "unhide" },
        { type: "separator" },
        { role: "quit" },
      ],
    },
    {
      label: "File",
      submenu: [
        {
          label: "Open File",
          accelerator: "Cmd+o",
          click: () => {
            mainWindow.webContents.send("openFileMenuClicked")
          },
        },
        { type: "separator" },
        {
          label: "Save File",
          accelerator: "Cmd+s",
          click: () => {
            mainWindow.webContents.send("saveFileMenuClicked")
          },
        },
        {
          label: "Save File As...",
          click: () => {
            mainWindow.webContents.send("saveFileAsMenuClicked")
          },
        },
      ],
    },
    {
      label: "Edit",
      submenu: [
        {
          label: "Undo",
          accelerator: "Cmd+z",
          click: () => {
            mainWindow.webContents.send("undoMenuClicked")
          },
        },
        {
          label: "Redo",
          accelerator: "Cmd+Shift+z",
          click: () => {
            mainWindow.webContents.send("redoMenuClicked")
          },
        },
        { type: "separator" },
        { role: "cut" },
        { role: "copy" },
        { role: "paste" },
        { type: "separator" },
        {
          label: "Up",
          accelerator: "Shift+Up",
          id: "up",
          enabled: false,
          click: () => {
            mainWindow.webContents.send("upMenuClicked")
          },
        },
        {
          label: "Down",
          accelerator: "Shift+Down",
          enabled: false,
          id: "down",
          click: () => {
            mainWindow.webContents.send("downMenuClicked")
          },
        },
        { type: "separator" },
        {
          label: "Edit",
          accelerator: "Cmd+E",
          id: "edit",
          enabled: false,
          click: () => {
            mainWindow.webContents.send("editMenuClicked")
          },
        },
        {
          label: "Keep Changes",
          accelerator: "Cmd+K",
          enabled: false,
          id: "keep",
          click: () => {
            mainWindow.webContents.send("keepChangesMenuClicked")
          },
        },
        {
          label: "Discard Changes",
          accelerator: "Cmd+D",
          enabled: false,
          id: "discard",
          click: () => {
            mainWindow.webContents.send("discardChangesMenuClicked")
          },
        },
        {
          label: "Delete",
          accelerator: "Cmd+Delete",
          enabled: false,
          id: "delete",
          click: () => {
            mainWindow.webContents.send("deleteMenuClicked")
          },
        },
        {
          label: "Append",
          enabled: false,
          id: "append",
          click: () => {
            mainWindow.webContents.send("appendMenuClicked")
          },
        },
        // { role: "cut" },
        // { role: "copy" },
        // { role: "paste" },
        // { role: "pasteandmatchstyle" },
        // { role: "delete" },
        // { role: "selectall" }
      ],
    },
    {
      label: "View",
      submenu: [
        { role: "reload" },
        { role: "forcereload" },
        { role: "toggledevtools" },
        { type: "separator" },
        { role: "resetzoom" },
        { role: "zoomin" },
        { role: "zoomout" },
        { type: "separator" },
        { role: "togglefullscreen" },
      ],
    },

    {
      role: "window",
      submenu: [
        { role: "minimize" },
        { role: "close" },
        { role: "zoom" },
        { type: "separator" },
        { role: "front" },
      ],
    },
    {
      role: "help",
      submenu: [
        {
          label: "Learn More",
          click() {
            require("electron").shell.openExternal(
              "https://github.com/noelrappin/deckset_editor"
            )
          },
        },
      ],
    },
  ])

  Menu.setApplicationMenu(menu)
}

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit()
  }
})

app.on("activate", () => {
  if (mainWindow === null) {
    createWindow()
  }
})
