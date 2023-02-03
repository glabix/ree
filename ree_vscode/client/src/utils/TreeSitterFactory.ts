import Ruby from 'web-tree-sitter-ruby'
import * as Parser from 'web-tree-sitter'

// eslint-disable-next-line @typescript-eslint/naming-convention
const TreeSitterFactory = {
	language: null,
	parser: null,

	async build(): Promise<Parser> {
		if (this.parser === null) {
			await Parser.init()
			this.parser = new Parser()
		}

		if (this.language === null) {
			this.language = await Parser.Language.load(Ruby)
		}

		this.parser.setLanguage(this.language)
		return this.parser
	},
}
export default TreeSitterFactory
