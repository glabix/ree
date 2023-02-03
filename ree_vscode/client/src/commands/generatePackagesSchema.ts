import * as vscode from 'vscode'
import { getProjectRootDir } from '../utils/packageUtils'
import { isReeInstalled, isBundleGemsInstalled, isBundleGemsInstalledInDocker, ExecCommand, spawnCommand } from '../utils/reeUtils'
import { buildReeCommandFullArgsArray } from '../utils/reeUtils'
import { logErrorMessage } from '../utils/stringUtils'

export function generatePackagesSchema(silent: boolean) {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showWarningMessage("Error. Open workspace folder to use extension")
    return
  }

  const rootProjectDir = getProjectRootDir(vscode.workspace.workspaceFolders[0].uri.path)
  if (!rootProjectDir) { return }

  const checkIsReeInstalled = isReeInstalled(rootProjectDir)?.then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(`CheckIsReeInstalledError: ${res.message}`)
      return null
    }
  })

  if (!checkIsReeInstalled) { return }

  const checkIsBundleGemsInstalled = isBundleGemsInstalled(rootProjectDir)?.then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(`CheckIsBundleGemsInstalledError: ${res.message}`)
      return
    }
  })
  if (!checkIsBundleGemsInstalled) { return }

  const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
  if (dockerPresented) {
    const checkIsBundleGemsInstalledInDocker = isBundleGemsInstalledInDocker()?.then((res) => {
      if (res.code !== 0) {
        vscode.window.showWarningMessage(`CheckIsBundleGemsInstalledInDockerError: ${res.message}`)
        return null
      }
    })

    if (!checkIsBundleGemsInstalledInDocker) {
      vscode.window.showWarningMessage("Docker option is enabled, but bundle gems not found in Docker container")
      return
    }
  }

  let result = execGeneratePackagesSchema(rootProjectDir)
  if (!result) {
    logErrorMessage("Can't generate Packages.schema.json")
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
      if (commandResult.code !== 0) {
        logErrorMessage(`GeneratePackagesSchemaError: ${commandResult.message}`)
        vscode.window.showErrorMessage(`GeneratePackagesSchemaError: ${commandResult.message}`)
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
    logErrorMessage(`Error. ${e.toString()}`)
    vscode.window.showErrorMessage(`Error. ${e.toString()}`)
    return undefined
  }
}

