import * as vscode from 'vscode'
import { PACKAGES_SCHEMA_FILE, PACKAGE_SCHEMA_FILE } from '../core/constants'
import { openDocument } from '../utils/documentUtils'
import { IPackageSchema, loadPackagesSchema } from '../utils/packagesUtils'
import { IObject, PackageFacade } from '../utils/packageFacade'
import { getProjectRootDir } from '../utils/packageUtils'
import { ObjectFacade } from '../utils/objectFacade'

var fs = require('fs')
var path = require("path")

type SelectPackageCb = (selected: string | undefined) => void;

export function goToPackageObject() {
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

    const p = packages.find(p => p.name === selected)
    const packageSchemaPath = path.join(projectPath, p?.schema)
    const entryPath = packageSchemaPath.split(PACKAGE_SCHEMA_FILE)[0] + `package/${p?.name}.rb`

    if (!fs.existsSync(entryPath)) {
      vscode.window.showErrorMessage(`Error. File not found: ${p?.name}/package/${p?.name}.rb`)
      return
    }

    const pkgFacade = new PackageFacade(packageSchemaPath)

    selectObject(pkgFacade.objects(), (selectedObj: string | undefined) => {
      if (selectedObj === undefined) { return }

      const obj = pkgFacade.objects().find(o => o.name === selectedObj)
      const objSchemaPath = path.join(projectPath, obj.schema)

      if (!fs.existsSync(objSchemaPath)) {
        vscode.window.showErrorMessage(
          `Error. Object schema file not found: ${objSchemaPath}. Re-generate schema for :${pkgFacade.name()} package`
        )
        return
      }
      const objFacade = new ObjectFacade(path.join(projectPath, obj.schema))
      const objectPath = path.join(projectPath, objFacade.path())

      if (!fs.existsSync(objectPath)) {
        vscode.window.showErrorMessage(`Error. File not found: ${objectPath}`)
        return
      }

      openDocument(objectPath)
    })
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