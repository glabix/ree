import * as vscode from 'vscode'
import { DiagnosticSeverity } from 'vscode-languageclient'
import { PackageFacade } from '../utils/packageFacade'
import { getPackageObjectFromCurrentPath } from '../utils/packageUtils'
import { getCurrentProjectDir } from '../utils/fileUtils'
import { 
  isReeInstalled,
  isBundleGemsInstalled,
  isBundleGemsInstalledInDocker,
  ExecCommand,
  genPackageSchemaJsonCommandArgsArray,
  buildReeCommandFullArgsArray,
  spawnCommand
} from '../utils/reeUtils'
import { diagnosticCollection } from '../extension'
import { addDocumentProblems, ReeDiagnosticCode, removeDocumentProblems } from '../utils/documentUtils'

const path = require('path')

export function generatePackageSchema(document: vscode.TextDocument, silent: boolean, packageName?: string) {
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
      vscode.window.showWarningMessage('Gem ree is not installed')
      return null
    }
  })

  if (!checkIsReeInstalled) { return }
  

  const checkIsBundleGemsInstalled = isBundleGemsInstalled(rootProjectDir).then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(res.message)
      return
    }
  })
  if (!checkIsBundleGemsInstalled) { return }

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
    const currentPackage = getCurrentPackage(fileName)
    if (!currentPackage) { return }

    execPackageName = currentPackage.name()
  }

  let result = execGeneratePackageSchema(rootProjectDir, execPackageName)
  if (!result) {
    vscode.window.showErrorMessage(`Can't generate Package.schema.json for ${execPackageName}`)
    return
  }

  vscode.window.withProgress({
    location: vscode.ProgressLocation.Notification
  }, async (progress) => {
    progress.report({
      message: `Generating "${execPackageName}" package schema...`
    })

    return result.then((commandResult) => {
      removeDocumentProblems(document.uri, ReeDiagnosticCode.reeDiagnostic)
    
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
          code: ReeDiagnosticCode.reeDiagnostic,
          source: 'ree'
        }
    
        diagnostics.push(diagnostic)
        addDocumentProblems(document.uri, diagnostics)
    
        return
      }
      
      if (!silent) {
        vscode.window.showInformationMessage(commandResult.message)
      }
    })
  })
}

export function execGeneratePackageSchema(rootProjectDir: string, name: string): Promise<ExecCommand> | undefined {
  try {
    const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string
    const projectDir = appDirectory ? appDirectory : rootProjectDir
    const fullArgsArr = buildReeCommandFullArgsArray(
      projectDir,
      genPackageSchemaJsonCommandArgsArray(projectDir, name)
    )

    return spawnCommand(fullArgsArr)
  } catch(e) {
    vscode.window.showErrorMessage(`Error. ${e}`)
    return undefined
  }
}

function getCurrentPackage(fileName?: string): PackageFacade | null {
  // check if active file/editor is accessible

  let currentFileName = fileName || vscode.window.activeTextEditor.document.fileName

  if (!currentFileName) {
    vscode.window.showErrorMessage("Open any package file")
    return
  }

  // finding package
  let currentPackage = getPackageObjectFromCurrentPath(currentFileName)

  if (!currentPackage) { return }

  return currentPackage
}



