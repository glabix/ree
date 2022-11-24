import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE, PACKAGE_SCHEMA_FILE } from '../core/constants'
import { openDocument } from '../utils/documentUtils'
import { IPackageSchema, IGemPackageSchema, loadPackagesSchema, getGemDir } from '../utils/packagesUtils'
import { IObject, PackageFacade } from '../utils/packageFacade'
import { getCurrentProjectDir } from '../utils/fileUtils'
import { ObjectFacade } from '../utils/objectFacade'

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

  const packagesSchema = loadPackagesSchema(projectPath)

  if (!packagesSchema) {
    vscode.window.showErrorMessage(`Unable to read ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  const allPackages = [...packagesSchema.packages, ...packagesSchema.gemPackages] as Array<IPackageSchema | IGemPackageSchema>
  let packageSchemaPath = null
  let projectRoot = null

  selectPackage(allPackages, (selected: string | undefined) => {
    if (selected === undefined) { return }

    const cleanedSelected = selected.replace(/\s\(.*\)/, '')
    const p = allPackages.find(p => p.name === cleanedSelected)
    if (!p) { return }

    projectRoot = projectPath
    if ('gem' in p) {
      projectRoot = getGemDir(p.name)
    }
    packageSchemaPath = path.join(projectRoot, p?.schema)
    const entryPath = packageSchemaPath.split(PACKAGE_SCHEMA_FILE)[0] + `package/${p?.name}.rb`

    if (!fs.existsSync(entryPath)) {
      vscode.window.showErrorMessage(`Error. File not found: ${p?.name}/package/${p?.name}.rb`)
      return
    }
  }).then(() => {
    const pkgFacade = new PackageFacade(packageSchemaPath)
  
    selectObject(pkgFacade.objects(), (selectedObj: string | undefined) => {
      if (selectedObj === undefined) { return }
  
      const obj = pkgFacade.objects().find(o => o.name === selectedObj)
      const objSchemaPath = path.join(projectRoot, obj.schema)
  
      if (!fs.existsSync(objSchemaPath)) {
        vscode.window.showErrorMessage(
          `Error. Object schema file not found: ${objSchemaPath}. Re-generate schema for :${pkgFacade.name()} package`
        )
        return
      }
      const objFacade = new ObjectFacade(path.join(projectRoot, obj.schema))
      const objectPath = path.join(projectRoot, objFacade.path())
  
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