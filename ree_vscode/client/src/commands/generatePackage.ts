import * as vscode from 'vscode'

import { getProjectRootDir } from '../utils/packageUtils'
import { isReeInstalled, ExecCommand } from '../utils/reeUtils'
import { loadPackagesSchema } from '../utils/packagesUtils'
import { PACKAGE_SCHEMA_FILE } from '../core/constants'
import { openDocument } from '../utils/documentUtils'

const fs = require('fs')
const path = require('path')

export function generatePackage() {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showWarningMessage("Error. Open workspace folder to use extension")
    return
  }

  let currentFilePath = null
  const activeEditor = vscode.window.activeTextEditor
  if (!activeEditor) {
    currentFilePath = vscode.workspace.workspaceFolders[0].uri.path
  } else {
    currentFilePath = activeEditor.document.fileName
  }

  const rootProjectDir = getProjectRootDir(currentFilePath)
  if (!rootProjectDir) { return }

  const checkReeIsInstalled = isReeInstalled(rootProjectDir)
  
  if (checkReeIsInstalled?.code === 1) {
    vscode.window.showWarningMessage('gem ree is not installed')
    return
  }

  const options: vscode.OpenDialogOptions = {
    defaultUri: vscode.Uri.parse(rootProjectDir),
    canSelectFolders: true,
    canSelectFiles: false,
    canSelectMany: false,
    openLabel: 'Select parent package folder',
  }

  vscode.window.showInputBox({placeHolder: 'Type package name...'}).then((name: string | undefined) => {
    if (!name) { return }

    if (!/^[a-z_0-9]+$/.test(name)) {
      vscode.window.showErrorMessage("Invalid package name. Name should contain a-z, 0-9 & _/")
      return
    }

    vscode.window.showOpenDialog(options).then(fileUri => {
      if (!fileUri || !fileUri[0]) { return }

      let rPath = path.relative(rootProjectDir, fileUri[0].path)
      rPath = path.join(rPath, name)

      const result = execGeneratePackage(rootProjectDir, rPath, name)

      if (!result) {
        vscode.window.showErrorMessage("Can't generate package")
        return
      }
    
      if (result.code === 1) {
        vscode.window.showErrorMessage(result.message)
        return
      }

      vscode.window.showInformationMessage(`Package ${name} was generated`)

      const packages = loadPackagesSchema(rootProjectDir)
      if (!packages) { return }

      const packageSchema = packages.find(p => p.name == name)
      if (!packageSchema) { return }

      const packageSchemaPath = path.join(rootProjectDir, packageSchema.schema)
      const entryPath = packageSchemaPath.split(PACKAGE_SCHEMA_FILE)[0] + `package/${packageSchema.name}.rb`

      if (!fs.existsSync(entryPath)) { return }
      openDocument(entryPath)
    })
  })
}

function execGeneratePackage(rootProjectDir: string, relativePath: string, name: string): ExecCommand | undefined {
  try {
    let spawnSync = require('child_process').spawnSync

    let child = spawnSync(
      'ree',
      ['gen.package', name.toString(), '--path', relativePath, '--project_path', rootProjectDir],
      { cwd: rootProjectDir }
    )

    return {
      message: child.status === 0 ? child.stdout.toString() : child.stderr.toString(),
      code: child.status
    }
  } catch(e) {
    vscode.window.showInformationMessage(`Error. ${e}`)
    return undefined
  }
}

