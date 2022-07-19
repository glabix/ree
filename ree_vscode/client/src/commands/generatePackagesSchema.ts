import * as vscode from 'vscode'
import { getProjectRootDir } from '../utils/packageUtils'
import { isReeInstalled, ExecCommand } from '../utils/reeUtils'
import { buildReeCommandFullArgsArray } from './generatePackageSchema'

export function generatePackagesSchema(silent: boolean) {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showWarningMessage("Error. Open workspace folder to use extension")
    return
  }

  const rootProjectDir = getProjectRootDir(vscode.workspace.workspaceFolders[0].uri.path)
  if (!rootProjectDir) { return }

  const checkReeIsInstalled = isReeInstalled(rootProjectDir)
  
  if (checkReeIsInstalled?.code === 1) {
    vscode.window.showWarningMessage('gem ree is not installed')
    return
  }

  let result = execGeneratePackagesSchema(rootProjectDir)

  if (!result) {
    vscode.window.showErrorMessage("Can't generate Packages.schema.json")
    return
  }

  if (result.code === 1) {
    vscode.window.showErrorMessage(result.message)
    return
  }
  
  if (!silent) {
    vscode.window.showInformationMessage(result.message)
  }
}

function execGeneratePackagesSchema(rootProjectDir: string): ExecCommand | undefined {
  try {
    let spawnSync = require('child_process').spawnSync

    let child = spawnSync(
      ...buildReeCommandFullArgsArray(rootProjectDir, ['gen.packages_json'])
    )

    return {
      message: child.status === 0 ? child.stdout.toString() : child.stderr.toString(),
      code: child.status
    }
  } catch(e) {
    vscode.window.showErrorMessage(`Error. ${e}`)
    return undefined
  }
}

