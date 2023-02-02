import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE, PACKAGE_SCHEMA_FILE } from '../core/constants'
import { openDocument } from '../utils/documentUtils'
import { IPackageSchema, IGemPackageSchema, getGemDir, getCachedIndex, isCachedIndexIsEmpty, IObject } from '../utils/packagesUtils'
import { getCurrentProjectDir } from '../utils/fileUtils'
import { logDebugClientMessage } from '../utils/stringUtils'

var fs = require('fs')
var path = require("path")

type SelectPackageCb = (selected: string | undefined) => void

export function goToPackageObject() {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showInformationMessage("Error. Open workspace folder to use extension")
    return
  }

  const projectPath = getCurrentProjectDir()
  if (!projectPath) {
    vscode.window.showErrorMessage(`Unable to find ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  logDebugClientMessage('Getting index in goToPackageObject Command')
  const index = getCachedIndex()
  if (isCachedIndexIsEmpty()) {
    logDebugClientMessage('Index is empty in goToPackageObject Command')
    return
  }

  const packagesSchema = index.packages_schema

  if (!packagesSchema) {
    vscode.window.showErrorMessage(`Unable to read ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  const allPackages = [...packagesSchema.packages, ...packagesSchema.gem_packages] as Array<IPackageSchema | IGemPackageSchema>
  let packageSchemaPath = null
  let projectRoot = null
  let selectedPackageName

  selectPackage(allPackages, (selected: string | undefined) => {
    if (selected === undefined) { return }

    const cleanedSelected = selected.replace(/\s\(.*\)/, '')
    selectedPackageName = cleanedSelected
    const p = allPackages.find(p => p.name === cleanedSelected)
    if (!p) { return }

    projectRoot = projectPath
    if ('gem' in p) {
      projectRoot = getGemDir(p.name)
    }
    packageSchemaPath = path.join(projectRoot, p?.schema_rpath)
    const entryPath = packageSchemaPath.split(PACKAGE_SCHEMA_FILE)[0] + `package/${p?.name}.rb`

    if (!fs.existsSync(entryPath)) {
      vscode.window.showErrorMessage(`Error. File not found: ${p?.name}/package/${p?.name}.rb`)
      return
    }
  }).then(() => {
    const selectedPackage: IPackageSchema | IGemPackageSchema = packagesSchema.packages.find(p => p.name === selectedPackageName) || 
                            packagesSchema.gem_packages.find(p => p.name === selectedPackageName)
  
    selectObject(selectedPackage.objects, (selectedObj: string | undefined) => {
      if (selectedObj === undefined) { return }
  
      const obj = selectedPackage.objects.find(o => o.name === selectedObj)
      const objSchemaPath = path.join(projectRoot, obj.schema_rpath)
  
      if (!fs.existsSync(objSchemaPath)) {
        vscode.window.showErrorMessage(
          `Error. Object schema file not found: ${objSchemaPath}. Re-generate schema for :${selectPackage.name} package`
        )
        return
      }
      const objectPath = path.join(projectRoot, obj.file_rpath)
  
      if (!fs.existsSync(objectPath)) {
        vscode.window.showErrorMessage(`Error. File not found: ${objectPath}`)
        return
      }
  
      openDocument(objectPath)
      }
    )
  })

}

function selectPackage(packages: Array<IPackageSchema | IGemPackageSchema>, cb: SelectPackageCb) {
  return new Promise(
    resolve => resolve(vscode
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
    )
  )
}

function selectObject(objects: IObject[], cb: SelectPackageCb) {
  vscode
    .window
    .showQuickPick(
      objects.map(p => p.name).sort(),
      {
        title: "Navigate to Package Object",
        placeHolder: "Type object name...",
      }
    )
    .then(
      (selected: string | undefined) => {
        cb(selected)
      }
    )
}