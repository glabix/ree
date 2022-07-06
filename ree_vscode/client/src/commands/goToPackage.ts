import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE, PACKAGE_SCHEMA_FILE } from '../core/constants'
import { openDocument } from '../utils/documentUtils'
import { IPackageSchema, loadPackagesSchema } from '../utils/packagesUtils'
import { getProjectRootDir } from '../utils/packageUtils'

var fs = require('fs')
var path = require("path")

type SelectPackageCb = (selected: string | undefined) => void;

export function goToPackage() {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showInformationMessage("Error. Open workspace folder to use extension")
    return
  }

  let currentFilePath = null
  const activeEditor = vscode.window.activeTextEditor
  if (!activeEditor) {
    currentFilePath = vscode.workspace.workspaceFolders[0].uri.path
  } else {
    currentFilePath = activeEditor.document.fileName
  }

  const projectPath = getProjectRootDir(currentFilePath)
  if (!projectPath) {
    vscode.window.showErrorMessage(`Unable to find ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  const packages = loadPackagesSchema(projectPath)

  if (!packages) {
    vscode.window.showErrorMessage(`Unable to read ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  selectPackage(packages, (selected: string | undefined) => {
    if (selected === undefined) { return }

    const p = packages.find(p => p.name == selected)
    const packageSchemaPath = path.join(projectPath, p?.schema)
    const entryPath = packageSchemaPath.split(PACKAGE_SCHEMA_FILE)[0] + `package/${p?.name}.rb`

    if (!fs.existsSync(entryPath)) {
      vscode.window.showErrorMessage(`Error. File not found: ${p?.name}/package/${p?.name}.rb`)
      return
    }

    openDocument(entryPath)
  })
}

function selectPackage(packages: IPackageSchema[], cb: SelectPackageCb) {
  vscode
    .window
    .showQuickPick(
      packages.map(p => p.name).sort(),
      {
        title: "Navigate to Ree Package",
        placeHolder: "Type package name...",
      }
    )
    .then(
      (selected: string | undefined) => {
        cb(selected)
      }
    )
}