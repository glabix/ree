import { Hover, HoverParams, Connection } from 'vscode-languageserver'
import Provider from './provider'
import HoverAnalyzer from '../analyzers/hoverAnalyzer'

export default class HoverProvider extends Provider {
	static register(connection: Connection): HoverProvider {
		return new HoverProvider(connection)
	}

	constructor(connection: Connection) {
		super(connection)
		this.connection.onHover(this.handleHover)
	}

	private handleHover = async (
		params: HoverParams
	): Promise<Hover> => {
		const { 
      textDocument: { uri },
      position
		} = params
		
    return Promise.resolve(
			HoverAnalyzer.analyze(uri, position)
		)
	}
}
