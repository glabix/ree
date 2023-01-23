import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE, PACKAGE_SCHEMA_FILE } from '../core/constants'
import { openDocument } from '../utils/documentUtils'
import { IGemPackageSchema, IPackageSchema, getGemDir, getCachedIndex, isCachedIndexIsEmpty } from '../utils/packagesUtils'
import { getCurrentProjectDir } from '../utils/fileUtils'

var fs = require('fs')
var path = require("path")

type SelectPackageCb = (selected: string | undefined) => void

export function goToPackage() {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showInformationMessage("Error. Open workspace folder to use extension")
    return
  }

  const projectPath = getCurrentProjectDir()
  if (!projectPath) {
    vscode.window.showErrorMessage(`Unable to find ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  const index = getCachedIndex()
  if (isCachedIndexIsEmpty()) { return }

  const packagesSchema = index.packages_schema

  if (!packagesSchema) {
    vscode.window.showErrorMessage(`Unable to read ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  const allPackages = [...packagesSchema.packages, ...packagesSchema.gem_packages] as Array<IPackageSchema | IGemPackageSchema>

  selectPackage(allPackages, (selected: string | undefined) => {
    if (selected === undefined) { return }

    const cleanedSelected = selected.replace(/\s\(.*\)/, '')
    const p = allPackages.find(p => p.name === cleanedSelected)
    if (!p) { return }

    let projectRoot = projectPath
    if ('gem' in p) {
      projectRoot = getGemDir(p.name)
    }
    const packageSchemaPath = path.join(projectRoot, p?.schema_rpath)
    const entryPath = packageSchemaPath.split(PACKAGE_SCHEMA_FILE)[0] + `package/${p?.name}.rb`

    if (!fs.existsSync(entryPath)) {
      vscode.window.showErrorMessage(`Error. File not found: ${p?.name}/package/${p?.name}.rb`)
      return
    }

    openDocument(entryPath)
  })
}

function selectPackage(packages: Array<IPackageSchema | IGemPackageSchema>, cb: SelectPackageCb) {
  vscode
    .window
    .showQuickPick(
      packages.map(p => (p && ('gem' in p)) ? `${p.name} (${p.gem})` : p.name).sort(),
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