import { CompletionItem, Connection } from 'vscode-languageserver'
import Provider from './provider'
import CompletionResolveAnalyzer from '../analyzers/completionResolveAnalyzer'

export default class CompletionResolveProvider extends Provider {
	static register(connection: Connection): CompletionResolveProvider {
		return new CompletionResolveProvider(connection)
	}

	constructor(connection: Connection) {
		super(connection)
		this.connection.onCompletionResolve(this.handleCompletionResolve)
	}

	private handleCompletionResolve = async (
		params: CompletionItem
	): Promise<CompletionItem> => {

    return CompletionResolveAnalyzer.analyze(params)
	}
}
