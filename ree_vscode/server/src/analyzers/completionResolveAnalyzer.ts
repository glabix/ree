import { CompletionItem, CompletionItemKind, MarkupContent, MarkupKind } from 'vscode-languageserver'
import { splitArgsType } from '../utils/tokenUtils'
import { getCachedIndex, isCachedIndexIsEmpty, IObject } from '../utils/packagesUtils'
import { logInfoMessage, LogLevel, sendDebugServerLogToClient } from '../utils/stringUtils'

const path = require('path')

export default class CompletionResolveAnalyzer {
	public static analyze(item: CompletionItem): CompletionItem {
    const index = getCachedIndex()
    if (isCachedIndexIsEmpty()) {
      logInfoMessage('Index is empty in completionResolveAnalyzer')
      return item
    } 

    if (item.data) {
      if (item.kind === CompletionItemKind.Method) {
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
            currentFilePath: item.data.currentFilePath,
            type: item.kind
          }]
        }

        const isGem = item.data.isGem
        let object = null
        if (isGem) {
          object = index.packages_schema.packages
                      .find(p => p.name === item.data.fromPackageName)
                      ?.objects.find(o => o.name === item.data.label)
        } else {
          object = index.packages_schema.gem_packages
                      .find(p => p.name === item.data.fromPackageName)
                      ?.objects.find(o => o.name === item.data.label)
        }
        
        if (object) {
          item.detail = `mount_as: ${object.mount_as}`
          item.documentation = this.buildMethodsDocumentation(object)
        }
      }

      if (item.kind === CompletionItemKind.Class) {
        item.command = {
          title: 'ree.updatePackageDeps',
          command: 'ree.updatePackageDeps',
          arguments: [{
            objectName: item.label,
            toPackageName: item.data.toPackageName,
            fromPackageName: item.data.fromPackageName,
            currentFilePath: item.data.currentFilePath,
            type: item.kind,
            linkPath: item.data.linkPath
          }]
        }
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

