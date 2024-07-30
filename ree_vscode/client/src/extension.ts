
import * as vscode from "vscode"
import * as path from 'path'
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind
} from 'vscode-languageclient/node'
import { goToPackage } from "./commands/goToPackage"
import { goToPackageObject } from "./commands/goToPackageObject"
import { updateStatusBar, statusBarCallbacks } from "./commands/statusBar"
import { goToSpec } from "./commands/goToSpec"
import { onCreatePackageFile, onRenamePackageFile } from "./commands/documentTemplates"
import { isBundleGemsInstalled, isBundleGemsInstalledInDocker } from "./utils/reeUtils"
import { generatePackagesSchema } from "./commands/generatePackagesSchema"
import { generatePackage } from "./commands/generatePackage"
import { getFileFromManager, updatePackageDeps } from './commands/updatePackageDeps'
import { selectAndGeneratePackageSchema } from './commands/selectAndGeneratePackageSchema'
import { reindexProject } from "./commands/reindexProject"
import { getCurrentProjectDir, isReeProject } from './utils/fileUtils'
import { forest } from './utils/forest'
import { clearDocumentProblems } from "./utils/documentUtils"
import { getNewProjectIndex } from "./utils/packagesUtils"
import { logDebugServerMessage } from "./utils/stringUtils"


export let client: LanguageClient
export const diagnosticCollection = vscode.languages.createDiagnosticCollection('ruby')
export const debugOutputClientChannel = vscode.window.createOutputChannel("Ree Debug Client")
export const debugOutputServerChannel = vscode.window.createOutputChannel("Ree Debug Server")

export async function activate(context: vscode.ExtensionContext) {
  let gotoPackageCmd = vscode.commands.registerCommand(
    "ree.goToPackage",
    goToPackage
  )

  let gotoPackageObjectCmd = vscode.commands.registerCommand(
    "ree.goToPackageObject",
    goToPackageObject
  )

  let goToSpecCmd = vscode.commands.registerCommand(
    "ree.goToSpec",
    goToSpec
  )

  let generatePackageSchemaCmd = vscode.commands.registerCommand(
    "ree.generatePackageSchema",
    selectAndGeneratePackageSchema
  )

  let generatePackagesSchemaCmd = vscode.commands.registerCommand(
    "ree.generatePackagesSchema",
    generatePackagesSchema
  )

  let generatePackageCmd = vscode.commands.registerCommand(
    "ree.generatePackage",
    generatePackage
  )

  let updatePackageDepsCmd = vscode.commands.registerCommand(
    "ree.updatePackageDeps",
    updatePackageDeps
  )

  let reindexProjectCmd = vscode.commands.registerCommand(
    "ree.reindexProject",
    reindexProject
  )

  let onDidOpenTextDocument = vscode.workspace.onDidOpenTextDocument(
    statusBarCallbacks.onDidOpenTextDocument
  )

  let onDidChangeActiveTextEditor = vscode.window.onDidChangeActiveTextEditor(
    statusBarCallbacks.onDidChangeActiveTextEditor
  )

  const onDidCreateFiles = vscode.workspace.onDidCreateFiles(
    (e: vscode.FileCreateEvent) => {
      onCreatePackageFile(e.files[0].path)
    }
  )

  const onDidRenameFiles = vscode.workspace.onDidRenameFiles(
    (e: vscode.FileRenameEvent) => {
      onRenamePackageFile(e.files[0].newUri.path)
      forest.deleteTree(e.files[0].oldUri.toString())

      if (e.files[0].newUri.path.split("/").pop().match(/\.rb/)) {
        getFileFromManager(e.files[0].newUri.path).then(file => {
          forest.createTree(e.files[0].newUri.toString(), file.getText())
        })
      }
    }
  )

  const onDidDeleteFiles = vscode.workspace.onDidDeleteFiles(
    (e: vscode.FileDeleteEvent) => {
      forest.deleteTree(e.files[0].toString())
    }
  )

  vscode.workspace.onDidSaveTextDocument(document => {
    if (document) {
      forest.updateTree(document.uri.toString(), document.getText())
    }
  })

  vscode.workspace.onDidCloseTextDocument(document => {
    if (document) {
      clearDocumentProblems(document.uri)
      forest.deleteTree(document.uri.toString())
    }
  })

  if (vscode.window.activeTextEditor) {
    updateStatusBar(vscode.window.activeTextEditor.document.fileName)
  }

  context.subscriptions.push(
    gotoPackageCmd,
    gotoPackageObjectCmd,
    goToSpecCmd,
    generatePackageSchemaCmd,
    generatePackagesSchemaCmd,
    generatePackageCmd,
    updatePackageDepsCmd,
    reindexProjectCmd,
    onDidOpenTextDocument,
    onDidChangeActiveTextEditor,
    onDidCreateFiles,
    onDidRenameFiles,
    onDidDeleteFiles,
  )

  if (!isReeProject()) { return } // register commands, but don't go further

  let curPath = getCurrentProjectDir()
  if (curPath) {
    getNewProjectIndex()
  }

  if (isBundleGemsInstalled(curPath)) {
    isBundleGemsInstalled(curPath).then((res) => {
      if (res.code !== 0) {
        vscode.window.showWarningMessage(`CheckIsBundleGemsInstalledError: ${res.message}`)
      }
    })
  }

  if (isBundleGemsInstalledInDocker()) {
    isBundleGemsInstalledInDocker().then((res) => {
      if (res && res.code !== 0) {
        vscode.window.showWarningMessage(`CheckIsBundleGemsInstalledInDockerError: ${res.message}`)
      }
    })
  }

  // Language Client

  let serverModule = context.asAbsolutePath(path.join('server', 'out', 'index.js'))
  // The debug options for the server
  // --inspect=6009: runs the server in Node's Inspector mode so VS Code can attach to the server for debugging
  let debugOptions = { execArgv: ['--nolazy', '--inspect=6009'] }

  // If the extension is launched in debug mode then the debug server options are used
  // Otherwise the run options are used
  let serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.ipc },
    debug: {
      module: serverModule,
      transport: TransportKind.ipc,
      options: debugOptions
    }
  }

  // Options to control the language client
  let clientOptions: LanguageClientOptions = {
    // Register the server for ruby documents
    documentSelector: [{ language: 'ruby' }, { language: 'slim' }],
    synchronize: {
      fileEvents: vscode.workspace.createFileSystemWatcher('**.rb')
    }
  }

  // Create the language client and start the client.
  client = new LanguageClient(
    'reeLanguageServer',
    'Ree Language Server',
    serverOptions,
    clientOptions
  )

  // Start the client. This will also launch the server
  client.start().then(() => {
    client.onNotification('reeLanguageServer/serverLog', (message) => {
      logDebugServerMessage(message)
    })
  })
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
		return undefined
	}
  forest.release()
	return client.stop()
}
