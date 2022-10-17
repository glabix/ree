import * as vscode from 'vscode'
import { DiagnosticSeverity } from 'vscode-languageclient'
import { PackageFacade } from '../utils/packageFacade'
import { getPackageNameFromPath } from '../utils/packageUtils'
import { loadPackagesSchema } from '../utils/packagesUtils'
import { getCurrentProjectDir } from '../utils/fileUtils'
import { 
  isReeInstalled,
  isBundleGemsInstalled,
  isBundleGemsInstalledInDocker,
  ExecCommand,
  genObjectSchemaJsonCommandArgsArray,
  buildReeCommandFullArgsArray,
  spawnCommand
} from '../utils/reeUtils'
import { PACKAGES_SCHEMA_FILE } from '../core/constants'

const path = require('path')
const diagnosticCollection = vscode.languages.createDiagnosticCollection('ruby')

export function clearDocumentProblems(document: vscode.TextDocument) {
  diagnosticCollection.delete(document.uri)
}

export function genObjectSchemaCmd() {
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

  const packagesSchema = loadPackagesSchema(projectPath)

  if (!packagesSchema) {
    vscode.window.showErrorMessage(`Unable to read ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  const currentPackageName = getPackageNameFromPath(currentFilePath)

  generateObjectSchema(activeEditor.document, false, currentPackageName)
}

export function generateObjectSchema(document: vscode.TextDocument, silent: boolean, packageName?: string) {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showWarningMessage("Error. Open workspace folder to use extension")
    return
  }

  const fileName = document.uri.path
  const rootProjectDir = getCurrentProjectDir()
  if (!rootProjectDir) { return }

  // check if ree is installed
  const checkIsReeInstalled = isReeInstalled(rootProjectDir).then((res) => {
    if (res.code === 1) {
      vscode.window.showWarningMessage(res.message)
      return null
    }
  })
  if (!checkIsReeInstalled) { return }

  const isBundleGemsInstalledResult = isBundleGemsInstalled(rootProjectDir).then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(res.message)
      return null
    }
  })
  if (!isBundleGemsInstalledResult) { return }

  const checkIsBundleGemsInstalledInDocker = isBundleGemsInstalledInDocker().then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(res.message)
      return null
    }
  })
  if (!checkIsBundleGemsInstalledInDocker) { return }

  let execPackageName = null

  if (packageName || packageName !== undefined) {
    execPackageName = packageName
  } else {
    const currentPackageName = getCurrentPackage(fileName)
    if (!currentPackageName) { return }

    execPackageName = currentPackageName
  }

  const result = execGenerateObjectSchema(rootProjectDir, execPackageName, fileName)

  if (!result) {
    vscode.window.showErrorMessage(`Can't generate Package.schema.json for ${execPackageName}`)
    return
  }

  result.then((commandResult) => {
    diagnosticCollection.delete(document.uri)

    if (commandResult.code === 1) {
      const rPath = path.relative(
        rootProjectDir, document.uri.path
      )

      const line = commandResult.message.split("\n").find(s => s.includes(rPath + ":"))
      let lineNumber = 0

      if (line) {
        try {
          lineNumber = parseInt(line.split(rPath)[1].split(":")[1])
        } catch {}
      }

      if (lineNumber > 0) {
        lineNumber -= 1
      }

      if (document.getText().length < lineNumber ) {
        lineNumber = 0
      }

      const character = document.getText().split("\n")[lineNumber].length - 1
      let diagnostics: vscode.Diagnostic[] = []

      let diagnostic: vscode.Diagnostic = {
        severity: DiagnosticSeverity.Error,
        range: new vscode.Range(
          new vscode.Position(lineNumber, 0),
          new vscode.Position(lineNumber, character)
        ),
        message: commandResult.message,
        source: 'ree'
      }

      diagnostics.push(diagnostic)
      diagnosticCollection.set(document.uri, diagnostics)

      return
    }
  
    if (!silent) {
      vscode.window.showInformationMessage(commandResult.message)
    }
  })
}

export async function execGenerateObjectSchema(rootProjectDir: string, name: string, objectPath: string): Promise<ExecCommand> {
  try {
    const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string
    const projectDir = appDirectory ? appDirectory : rootProjectDir
    const fullArgsArr = buildReeCommandFullArgsArray(projectDir, genObjectSchemaJsonCommandArgsArray(projectDir, name, objectPath))

    return spawnCommand(fullArgsArr)
  } catch(e) {
    vscode.window.showErrorMessage(`Error. ${e}`)
    return undefined
  }
}

function getCurrentPackage(fileName?: string): string | null {
  // check if active file/editor is accessible

  let currentFileName = fileName || vscode.window.activeTextEditor.document.fileName

  if (!currentFileName) {
    vscode.window.showErrorMessage("Open any package file")
    return
  }

  // finding package
  let currentPackage = getPackageNameFromPath(currentFileName)

  if (!currentPackage) { return }

  return currentPackage
}



