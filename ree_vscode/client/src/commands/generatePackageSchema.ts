import * as vscode from 'vscode'
import { DiagnosticSeverity } from 'vscode-languageclient'
import { PackageFacade } from '../utils/packageFacade'
import { getPackageObjectFromCurrentPath, getProjectRootDir } from '../utils/packageUtils'
import { isReeInstalled, ExecCommand } from '../utils/reeUtils'

const path = require('path')
const diagnosticCollection = vscode.languages.createDiagnosticCollection('ruby')

export function clearDocumentProblems(document: vscode.TextDocument) {
  diagnosticCollection.delete(document.uri)
}

export function generatePackageSchema(document: vscode.TextDocument, silent: boolean, packageName?: string, fileName?: string) {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showWarningMessage("Error. Open workspace folder to use extension")
    return
  }

  let currentFilePath = null
  const activeEditor = vscode.window.activeTextEditor

  if (!activeEditor) {
    currentFilePath = vscode.workspace.workspaceFolders[0].uri.path
  } else {
    currentFilePath = activeEditor.document.fileName
  }

  const rootProjectDir = getProjectRootDir(currentFilePath)

  if (!rootProjectDir) { return }

  // check if ree is installed
  const checkReeIsInstalled = isReeInstalled(rootProjectDir)
  
  if (checkReeIsInstalled?.code === 1) {
    vscode.window.showWarningMessage('gem ree is not installed')
    return
  }

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

  diagnosticCollection.delete(document.uri)

  if (result.code === 1) {
    const rPath = path.relative(
      rootProjectDir, document.uri.path
    )

    const line = result.message.split("\n").find(s => s.includes(rPath + ":"))
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
      message: result.message,
      source: 'ree'
    }

    diagnostics.push(diagnostic)
    diagnosticCollection.set(document.uri, diagnostics)

    return
  }
  
  if (!silent) {
    vscode.window.showInformationMessage(result.message)
  }
}

export function execGeneratePackageSchema(rootProjectDir: string, name: string): ExecCommand | undefined {
  try {
    let spawnSync = require('child_process').spawnSync
    const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string
    const projectDir = appDirectory ? appDirectory : rootProjectDir
    const fullArgsArr = buildFullArgsArray(projectDir, getArgsArray(projectDir, name))
    const child = spawnSync(...fullArgsArr)

    return {
      message: child.status === 0 ? child?.stdout?.toString() : child?.stderr?.toString(),
      code: child.status
    }
  } catch(e) {
    vscode.window.showErrorMessage(`Error. ${e}`)
    return undefined
  }
}

function getArgsArray(projectDir: string, name?: string) {
  if (name) { return ['gen.package_json', name.toString(), '--project_path', projectDir, '--trace'] }
  
  return  ['gen.package_json', '--project_path', projectDir, '--trace']
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

export function buildFullArgsArray(rootProjectDir: string, argsArray: string[]): Array<any> {
  let projectDir = rootProjectDir
  const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
  const containerName = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('containerName') as string
  const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string

  if (dockerPresented) {
    projectDir = appDirectory
    return [
      'docker', [
        'exec',
        '-i',
        '-e',
        'REE_SKIP_ENV_VARS_CHECK=true',
        '-w',
        '/app',
        containerName,
        'bundle',
        'exec',
        'ree',
        ...argsArray
      ]
    ]
  } else {
    return [
      'env', [
        'REE_SKIP_ENV_VARS_CHECK=true',
        'ree',
        ...argsArray,
      ],
      {
        cwd: projectDir
      }
    ]
  }
}

