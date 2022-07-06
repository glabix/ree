import { CompletionItem, CompletionParams, Connection, TextDocumentPositionParams } from 'vscode-languageserver';
import Provider from './provider';
import CompletionAnalyzer from '../analyzers/completionAnalyzer';

export default class CompletionProvider extends Provider {
	static register(connection: Connection): CompletionProvider {
		return new CompletionProvider(connection);
	}

	constructor(connection: Connection) {
		super(connection);
		this.connection.onCompletion(this.handleCompletion);
	}

	private handleCompletion = async (
		params: CompletionParams
	): Promise<CompletionItem[]> => {
    const {
      textDocument: { uri },
      position
    } = params

    return CompletionAnalyzer.analyze(uri, position)
	};
}
