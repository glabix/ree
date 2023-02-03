import * as vscode from 'vscode'
import { DiagnosticSeverity } from 'vscode-languageclient'
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
import { addDocumentProblems, ReeDiagnosticCode, removeDocumentProblems } from '../utils/documentUtils'
import { getCurrentPackage } from './generateObjectSchema'

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
  const checkIsReeInstalled = isReeInstalled(rootProjectDir)?.then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(`CheckIsReeInstalledError: ${res.message}`)
      return null
    }
  })

  if (!checkIsReeInstalled) { return }
  

  const checkIsBundleGemsInstalled = isBundleGemsInstalled(rootProjectDir)?.then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(`CheckIsBundleGemsInstalledError: ${res.message}`)
      return
    }
  })
  if (!checkIsBundleGemsInstalled) { return }

  const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
  if (dockerPresented) {
    const checkIsBundleGemsInstalledInDocker = isBundleGemsInstalledInDocker()?.then((res) => {
      if (res.code !== 0) {
        vscode.window.showWarningMessage(`CheckIsBundleGemsInstalledInDockerError: ${res.message}`)
        return null
      }
    })

    if (!checkIsBundleGemsInstalledInDocker) {
      vscode.window.showWarningMessage("Docker option is enabled, but bundle gems not found in Docker container")
      return
    }
  }

  let execPackageName = null

  if (packageName || packageName !== undefined) {
    execPackageName = packageName
  } else {
    const currentPackage = getCurrentPackage(fileName)
    if (!currentPackage) { return }

    execPackageName = currentPackage
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
      message: execPackageName !== null ? `Generating "${execPackageName}" package schema...` : `Generating schemas for all packages...`
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



