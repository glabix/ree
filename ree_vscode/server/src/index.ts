/**
 * LSP server for Ree
 */

 import {
	createConnection,
	Connection,
	InitializeParams,
	ProposedFeatures,
} from 'vscode-languageserver/node'
import log from 'loglevel'

import { ILanguageServer } from './server'
import TreeSitterFactory from './utils/treeSitterFactory'

const connection: Connection = createConnection(ProposedFeatures.all)
let server: ILanguageServer

connection.onInitialize(async (params: InitializeParams) => {
	log.setDefaultLevel('info')
	log.info('Initializing Ruby language server...')

	await TreeSitterFactory.initalize()

	log.info('TreeSitterFactory initialized')

	const { Server } = await import('./server')
	server = new Server(connection, params)
	server.initialize()

	return server.capabilities
})

connection.onInitialized(() => {
	server.setup()
})

connection.onShutdown(() => server.shutdown())
connection.onExit(() => server.shutdown())

// Listen on the connection
connection.listen()

// Don't die on unhandled Promise rejections
process.on('unhandledRejection', (reason, p) => {
	log.error(`Unhandled Rejection at: Promise ${p} reason:, ${reason}`)
})

// Don't die when attempting to pipe stdin to a bad spawn
// https://github.com/electron/electron/issues/13254
process.on('SIGPIPE', () => {
	log.error('SIGPIPE received')
})
