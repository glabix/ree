
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
import { clearDocumentProblems, generatePackageSchema } from './commands/generatePackageSchema'
import { updateStatusBar, statusBarCallbacks } from "./commands/statusBar"
import { goToSpec } from "./commands/goToSpec"
import { onCreatePackageFile, onRenamePackageFile } from "./commands/documentTemplates"
import { isBundleGemsInstalled, isBundleGemsInstalledInDocker } from "./utils/reeUtils"
import { getCurrentProjectDir } from './utils/fileUtils'
import { generatePackagesSchema } from "./commands/generatePackagesSchema"
import { generatePackage } from "./commands/generatePackage"
import { updatePackageDeps } from './commands/updatePackageDeps'
import { selectAndGeneratePackageSchema } from './commands/selectAndGeneratePackageSchema'

let client: LanguageClient

export function activate(context: vscode.ExtensionContext) {
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
    } 
  )

  vscode.workspace.onDidSaveTextDocument(document => {
    if (document) {
      generatePackageSchema(document, true) 
    }
  })

  vscode.workspace.onDidCloseTextDocument(document => {
    if (document) {
      clearDocumentProblems(document) 
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
    onDidOpenTextDocument,
    onDidChangeActiveTextEditor,
    onDidCreateFiles,
    onDidRenameFiles,
  )


  let curPath = getCurrentProjectDir()
  const checkIsBundleGemsInstalled = isBundleGemsInstalled(curPath)
  if (checkIsBundleGemsInstalled?.code !== 0) {
    vscode.window.showWarningMessage("Unable to find gems. Run `bundle install` first.")
  }

  const checkIsBundleGemsInstalledInDocker = isBundleGemsInstalledInDocker()
  if (checkIsBundleGemsInstalledInDocker && checkIsBundleGemsInstalledInDocker.code !== 0) {
    vscode.window.showWarningMessage("Unable to find gems in Docker container. Run `bundle install` in container first.")
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
    documentSelector: [{ language: 'ruby' }],
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
  client.start()
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
		return undefined
	}
	return client.stop()
}
