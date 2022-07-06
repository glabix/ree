import { CompletionItem, CompletionItemKind, MarkupContent, MarkupKind } from 'vscode-languageserver'
import { forest } from '../forest'
import { splitArgsType } from '../utils/tokenUtils'
import { loadObjectSchema, IObjectMethod, IObject } from '../utils/objectUtils'

const path = require('path')

export default class CompletionResolveAnalyzer {
	public static analyze(item: CompletionItem): CompletionItem {
    if (item.data) {
      item.labelDetails = {
        description: `from: ${item.data.fromPackageName}`
      }
      item.command = {
        title: 'ree.updatePackageDeps',
        command: 'ree.updatePackageDeps',
        arguments: [{
          objectName: item.label,
          toPackageName: item.data.toPackageName,
          fromPackageName: item.data.fromPackageName,
          currentFilePath: item.data.currentFilePath
        }]
      }

      const schema = loadObjectSchema(
        path.join(item.data.projectRootDir, item.data.objectSchema)
      )
      if (schema) {
        item.detail = `mount_as: ${schema.mount_as}`
        item.documentation = this.buildMethodsDocumentation(schema)
      }
    }

    return item
  }

  private static buildMethodsDocumentation(schema: IObject): MarkupContent {
    let content = {
      kind: MarkupKind.Markdown,
      value: ''
    }

    let mrkdwnArr: string[] = []

    schema.methods.map(m => {
      if (m.doc) {
        mrkdwnArr.push(m.doc)
      }

      if (m.args) {
        let argsStr = ''
        if (m.args.length > 1) {
          argsStr = m.args.map(arg => (
            `  ${arg.arg}: ${splitArgsType(arg.type)}`
          )).join(',  \n')
        } else {
          argsStr = m.args.map(arg => (
            `  ${arg.arg}: ${splitArgsType(arg.type)}`
          )).join()
        }

        let argsDoc = `\`\`\`ruby\n${schema.name}(  \n${argsStr}  \n) => ${m.return ? m.return : ''}\n\`\`\``

        mrkdwnArr.push(argsDoc)
      }
    })

    if (mrkdwnArr.length > 0) { mrkdwnArr.unshift('Methods:\n') }

    content.value = mrkdwnArr.join('\n')
    return content
  }
}

