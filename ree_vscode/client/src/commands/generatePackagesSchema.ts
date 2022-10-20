import * as vscode from 'vscode'
import { getProjectRootDir } from '../utils/packageUtils'
import { isReeInstalled, isBundleGemsInstalled, isBundleGemsInstalledInDocker, ExecCommand, spawnCommand } from '../utils/reeUtils'
import { buildReeCommandFullArgsArray } from '../utils/reeUtils'

export function generatePackagesSchema(silent: boolean) {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showWarningMessage("Error. Open workspace folder to use extension")
    return
  }

  const rootProjectDir = getProjectRootDir(vscode.workspace.workspaceFolders[0].uri.path)
  if (!rootProjectDir) { return }

  const checkIsReeInstalled = isReeInstalled(rootProjectDir).then((res) => {
    if (res.code === 1) {
      vscode.window.showWarningMessage('Gem ree is not installed')
      return null
    }
  })

  if (!checkIsReeInstalled) { return }

  const checkIsBundleGemsInstalled = isBundleGemsInstalled(rootProjectDir).then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(res.message)
      return
    }
  })
  if (!checkIsBundleGemsInstalled) { return }

  const checkIsBundleGemsInstalledInDocker = isBundleGemsInstalledInDocker().then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(res.message)
      return null
    }
  })
  if (!checkIsBundleGemsInstalledInDocker) { return }

  let result = execGeneratePackagesSchema(rootProjectDir)
  if (!result) {
    vscode.window.showErrorMessage("Can't generate Packages.schema.json")
    return
  }

  vscode.window.withProgress({
    location: vscode.ProgressLocation.Notification
  }, async (progress) => {
    progress.report({
      message: `Generating Packages.schema.json...`
    })

    return result.then((commandResult) => {
      if (commandResult.code === 1) {
        vscode.window.showErrorMessage(commandResult.message)
        return
      }
      
      if (!silent) {
        vscode.window.showInformationMessage(commandResult.message)
      }
    })
  })
}

function execGeneratePackagesSchema(rootProjectDir: string): Promise<ExecCommand> | undefined {
  try {
    return spawnCommand(
      buildReeCommandFullArgsArray(rootProjectDir, ['gen.packages_json'])
    )
  } catch(e) {
    vscode.window.showErrorMessage(`Error. ${e}`)
    return undefined
  }
}

