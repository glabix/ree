
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
import { genObjectSchemaCmd, generateObjectSchema } from "./commands/generateObjectSchema"
import { generatePackage } from "./commands/generatePackage"
import { getFileFromManager, updatePackageDeps } from './commands/updatePackageDeps'
import { selectAndGeneratePackageSchema } from './commands/selectAndGeneratePackageSchema'
import { onDeletePackageFile } from "./commands/deleteObjectSchema"
import { forest } from './utils/forest'
import { cacheGemPaths, setCachedPackages, parsePackagesSchema, setCachedGems } from "./utils/packagesUtils"
import { PACKAGES_SCHEMA_FILE } from "./core/constants"

const fs = require('fs')
let client: LanguageClient

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

  let generateObjectSchemaCmd = vscode.commands.registerCommand(
    "ree.generateObjectSchema",
    genObjectSchemaCmd
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
      generateObjectSchema(e.files[0].path, true)
    } 
  )

  const onDidRenameFiles = vscode.workspace.onDidRenameFiles(
    (e: vscode.FileRenameEvent) => {
      onRenamePackageFile(e.files[0].newUri.path)
      onDeletePackageFile(e.files[0].oldUri.path)
      forest.deleteTree(e.files[0].oldUri.toString())
      generateObjectSchema(e.files[0].newUri.path, true)
      if (e.files[0].newUri.path.split("/").pop().match(/\.rb/)) {
        getFileFromManager(e.files[0].newUri.path).then(file => {
          forest.createTree(e.files[0].newUri.toString(), file.getText())
        })
      }
    } 
  )

  const onDidDeleteFiles = vscode.workspace.onDidDeleteFiles(
    (e: vscode.FileDeleteEvent) => {
      onDeletePackageFile(e.files[0].path)
      forest.deleteTree(e.files[0].toString())
    } 
  )

  vscode.workspace.onDidSaveTextDocument(document => {
    if (document) {
      forest.updateTree(document.uri.toString(), document.getText())
      generateObjectSchema(document.fileName, true)
    }
  })

  vscode.workspace.onDidCloseTextDocument(document => {
    if (document) {
      clearDocumentProblems(document)
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
    generateObjectSchemaCmd,
    generatePackageCmd,
    updatePackageDepsCmd,
    onDidOpenTextDocument,
    onDidChangeActiveTextEditor,
    onDidCreateFiles,
    onDidRenameFiles,
    onDidDeleteFiles,
  )

  let curPath = getCurrentProjectDir()
  cacheGemPaths(curPath).then((r) => {
    const gemPathsArr = r?.message.split("\n")
      gemPathsArr?.map((path) => {
        let splitedPath = path.split("/")
        let name = splitedPath[splitedPath.length - 1].replace(/\-(\d+\.?)+/, '')

        setCachedGems(name, path)
      })

      setCachedPackages(
        parsePackagesSchema(
          fs.readFileSync(path.join(curPath, PACKAGES_SCHEMA_FILE),{ encoding: 'utf8' }),
          path.join(curPath, PACKAGES_SCHEMA_FILE)
        )
      )
  })

  if (isBundleGemsInstalled(curPath)) {
    isBundleGemsInstalled(curPath).then((res) => {
      if (res.code !== 0) {
        vscode.window.showWarningMessage(res.message)
      }
    })
  }

  if (isBundleGemsInstalledInDocker()) {
    isBundleGemsInstalledInDocker().then((res) => {
      if (res && res.code !== 0) {
        vscode.window.showWarningMessage(res.message)
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
  forest.release()
	return client.stop()
}
