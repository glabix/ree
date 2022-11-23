import { TextDocuments, Connection, TextDocumentIdentifier } from 'vscode-languageserver'
import { TextDocument } from 'vscode-languageserver-textdocument'
import { Subject } from 'rxjs'
import { forest } from './forest'
import { cacheFileIndex, getCachedIndex, setCachedIndex } from './utils/packagesUtils'
import { getProjectRootDir } from './utils/packageUtils'
import { Server } from 'http'
import { connection } from '.'
const url = require('url')
const path = require('path')

export enum DocumentEventKind {
	OPEN,
	CHANGE_CONTENT,
	CLOSE,
}

export interface DocumentEvent {
	kind: DocumentEventKind
	document: TextDocument
}

export default class DocumentManager {
	private readonly documents: TextDocuments<TextDocument>

	constructor() {
		this.documents = new TextDocuments(TextDocument)

		this.documents.onDidOpen((e) => {
			forest.createTree(e.document.uri, e.document.getText())
		})

		this.documents.onDidChangeContent((e) => {
			forest.updateTree(e.document.uri, e.document.getText())
		})

		this.documents.onDidSave((e) => {
			// TODO: move this to some function
			let filePath = url.fileURLToPath(e.document.uri)
			let root = getProjectRootDir(filePath)

			let rFilePath = path.relative(root, filePath)
			if (root) {
				cacheFileIndex(root,rFilePath).then(r => {
					if (r) {
						if (r.code === 0) {
							try {
								let index = getCachedIndex()
								let newIndexForFile = JSON.parse(r.message)
								if (Object.keys(newIndexForFile).length === 0) { return }
	
								let classConst = Object.keys(newIndexForFile)?.[0]
								const oldIndex = index.classes[classConst].findIndex(v => v.path.match(RegExp(`${rFilePath}`)))
								if (oldIndex !== -1) {
									index.classes[classConst][oldIndex].methods = newIndexForFile[classConst].methods
									index.classes[classConst][oldIndex].package = newIndexForFile[classConst].package
								} else {
									index.classes[classConst].push(newIndexForFile)
								}
		
								setCachedIndex(index)
							} catch (e: any) {
								connection.window.showErrorMessage(e)	
							}
						} else {
							connection.window.showErrorMessage(r.message)
						}
					}
				})
			}
		})

		this.documents.onDidClose((e) => {
			forest.deleteTree(e.document.uri)
		})
	}

	public get(id: TextDocumentIdentifier | string): TextDocument {
		const docId = typeof id === 'string' ? id : id.uri
		return this.documents.get(docId)!
	}

	public listen(connection: Connection): void {
		this.documents.listen(connection)
	}
}

export const documents = new DocumentManager()
