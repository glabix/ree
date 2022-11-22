const fs = require('fs')
const path = require('path')

export function getReeVscodeSettings(rootDir: string) {
  let settingsFilePath = path.join(rootDir, '.vscode', 'settings.json')

  if (fs.existsSync(settingsFilePath)) {
    const data = fs.readFileSync(settingsFilePath, {encoding: 'utf-8'})
    const settings = JSON.parse(data)
    return {
      dockerAppDirectory: settings['reeLanguageServer.docker.appDirectory'],
      dockerContainerName: settings['reeLanguageServer.docker.containerName'],
      dockerPresented: settings['reeLanguageServer.docker.presented']
    }
  }

  return {}
}