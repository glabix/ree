import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE } from '../core/constants'
import { IPackageSchema, loadPackagesSchema } from '../utils/packagesUtils'
import { getPackageNameFromPath, getProjectRootDir } from '../utils/packageUtils'
import { generatePackageSchema } from './generatePackageSchema'

type SelectPackageCb = (selected: string | undefined) => void;

export function selectAndGeneratePackageSchema() {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showInformationMessage("Error. Open workspace folder to use extension")
    return
  }

  let currentFilePath = null
  const activeEditor = vscode.window.activeTextEditor

  if (!activeEditor) {
    currentFilePath = vscode.workspace.workspaceFolders[0].uri.path
  } else {
    currentFilePath = activeEditor.document.uri.path
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

  const currentPackageName = getPackageNameFromPath(currentFilePath)
  const allPackageOption = { name: 'All Packages', schema: null }

  const filteredPackages = [
    allPackageOption,
    ...packages.filter(p => {
      if (p.name === currentPackageName) { p.name = 'Current Package' }
      return p
   })
  ]
   

  selectPackage(filteredPackages, (selected: string | undefined) => {
    if (selected === undefined) { return }

    let packageName = null
    if (selected === 'Current Package') {
      packageName = currentPackageName
    } else if (selected === 'All Packages') {
      packageName = null
    } else {
      packageName = selected
    }

    generatePackageSchema(activeEditor.document, false, packageName)
  })
}

function selectPackage(packages: IPackageSchema[], cb: SelectPackageCb) {
  vscode
    .window
    .showQuickPick(
      packages.map(p => p.name).sort(),
      {
        title: "Select Ree Package for Package.schema.json generation...",
        placeHolder: "Type package name...",
      }
    )
    .then(
      (selected: string | undefined) => {
        cb(selected)
      }
    )
}