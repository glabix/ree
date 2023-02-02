import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE } from '../core/constants'
import { getCachedIndex, IPackageSchema, isCachedIndexIsEmpty } from '../utils/packagesUtils'
import { getCurrentProjectDir } from '../utils/fileUtils'
import { getPackageNameFromPath } from '../utils/packageUtils'
import { generatePackageSchema } from './generatePackageSchema'
import { logDebugClientMessage } from '../utils/stringUtils'

type SelectPackageCb = (selected: string | undefined) => void

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

  const projectPath = getCurrentProjectDir()
  if (!projectPath) {
    vscode.window.showErrorMessage(`Unable to find ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  logDebugClientMessage('Getting index in selectAndGeneratePackageSchema Command')
  const index = getCachedIndex()
  if (isCachedIndexIsEmpty()) {
    logDebugClientMessage('Index is empty in selectAndGeneratePackageSchema Command')
    return
  }

  const packagesSchema = index.packages_schema

  if (!packagesSchema) {
    vscode.window.showErrorMessage(`Unable to read ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  const currentPackageName = getPackageNameFromPath(currentFilePath)
  // eslint-disable-next-line @typescript-eslint/naming-convention
  const allPackageOption = { name: 'All Packages', schema_rpath: null } as IPackageSchema

  const filteredPackages = [
    allPackageOption,
    ...packagesSchema.packages.filter(p => {
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