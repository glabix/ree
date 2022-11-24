import { Location, DefinitionParams, Connection } from 'vscode-languageserver'
import Provider from './provider'
import DefinitionAnalyzer from '../analyzers/definitionAnalyzer'

export default class DefinitionProvider extends Provider {
	static register(connection: Connection): DefinitionProvider {
		return new DefinitionProvider(connection)
	}

	constructor(connection: Connection) {
		super(connection)
		this.connection.onDefinition(this.handleDefinition)
	}

	private handleDefinition = async (
		params: DefinitionParams
	): Promise<Location> => {
		const { 
      textDocument: { uri },
      position
		} = params
		
    return DefinitionAnalyzer.analyze(uri, position)
	}
}
