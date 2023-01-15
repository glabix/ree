import {
	Connection,
	InitializeParams,
	InitializeResult,
} from 'vscode-languageserver'
import { CapabilityCalculator } from './capabilityCalculator'
import DefinitionProvider from './providers/definitionProvider'
import HoverProvider from './providers/hoverProvider'
import CompletionProvider from './providers/completionProvider'
import CompletionResolveProvider from './providers/completionResolveProvider'
import { documents } from './documentManager'
import { forest } from './forest'
import { cacheProjectIndex, ICachedIndex, setCachedIndex, cacheGemPaths, getCachedIndex } from './utils/packagesUtils'

const url = require('url')

export interface ILanguageServer {
	readonly capabilities: InitializeResult
  initialize(): void
  setup(): void
  shutdown(): void
}

export class Server implements ILanguageServer {
	public connection: Connection
	private calculator: CapabilityCalculator

	constructor(connection: Connection, params: InitializeParams) {
		this.connection = connection
		this.calculator = new CapabilityCalculator(params.capabilities)

		documents.listen(connection)
	}

	get capabilities(): InitializeResult {
		return {
			capabilities: this.calculator.capabilities,
		}
	}

	/**
	 * Initialize should be run during the initialization phase of the client connection
	 */
	public initialize(): void {
		this.registerInitializeProviders()
	}

	/**
	 * Setup should be run after the client connection has been initialized. We can do things here like
	 * handle changes to the workspace and query configuration settings
	 */
	public setup(): void {
		this.registerInitializedProviders()

		this.connection.workspace.getWorkspaceFolders().then(v => {
			return v?.map(folder => folder)
		}).then(v => {
			if (v) { 
				const folder = v[0]
				const root = url.fileURLToPath(folder.uri) 

				cacheProjectIndex(root).then(r => {
					try {
						if (r) {
							if (r.code === 0) {
								setCachedIndex(JSON.parse(r.message))
							} else {
								this.connection.window.showErrorMessage(`GetProjectIndexError: ${r.message.toString()}`)
							}
						}
					}	catch (e: any) {
						setCachedIndex(<ICachedIndex>{})
						this.connection.window.showErrorMessage(e.toString())
					}
				}).then(() => {
					cacheGemPaths(root.toString()).then((r) => {
						const gemPathsArr = r?.message.split("\n")
						const index = getCachedIndex()
						index.gem_paths ??= {}

						gemPathsArr?.map((path) => {
							let splitedPath = path.split("/")
							let name = splitedPath[splitedPath.length - 1].replace(/\-(\d+\.?)+/, '')
			
							index.gem_paths[name] = path
						})

						setCachedIndex(index)
					})
				})
			}
		})
	}

	public shutdown(): void {
		forest.release()
	}

	// registers providers on the initialize step
	private registerInitializeProviders(): void {
    DefinitionProvider.register(this.connection)
		HoverProvider.register(this.connection)
		CompletionProvider.register(this.connection)
		CompletionResolveProvider.register(this.connection)
	}

	// registers providers on the initialized step
	private registerInitializedProviders(): void {
		// TODO
	}
}
