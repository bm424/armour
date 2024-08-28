const { app, BrowserWindow } = require('electron')
const { updateElectronApp } = require('update-electron-app');
updateElectronApp(); // additional configuration options available

const createWindow = () => {
    const win = new BrowserWindow({width: 800, height: 600})

    win.loadFile("index.html")
}

app.whenReady().then(() => {
    createWindow()

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow()
      })
})

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit()
  })