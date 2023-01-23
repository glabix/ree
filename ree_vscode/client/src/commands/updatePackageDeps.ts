import * as vscode from 'vscode'
import { forest, mapLinkQueryMatches } from '../utils/forest'
import { Query } from 'web-tree-sitter'
import { CompletionItemKind } from 'vscode-languageclient'

const TAB_LENGTH = 2

export function updatePackageDeps(
  { objectName,
    toPackageName,
    fromPackageName,
    currentFilePath,
    type,
    linkPath
   } : {
      objectName: string,
      fromPackageName: string
      toPackageName: string
      currentFilePath: string,
      type: CompletionItemKind,
      linkPath?: string
    }
  ) { 
    getFileFromManager(currentFilePath).then(currentFile => {
      updateObjectLinks(currentFile, objectName, fromPackageName, toPackageName, type, linkPath)
    })
}

export function getFileFromManager(filePath: string): Thenable<vscode.TextDocument> {
  const textDocs = vscode.workspace.textDocuments

  if (textDocs.map(t => t.fileName).includes(filePath)) {
    return new Promise(resolve => resolve(textDocs.filter(t => t.fileName === filePath)[0]))
  } else {
    return vscode.workspace.openTextDocument(vscode.Uri.parse(filePath)).then((f: vscode.TextDocument) => { return f }) 
  }
}

function updateObjectLinks(
  currentFile: vscode.TextDocument,
  objectName: string,
  fromPackageName: string,
  toPackageName: string,
  type: CompletionItemKind,
  linkPath?: string
  ): Thenable<boolean> | null {
  
  const uri = currentFile.uri  
  let tree = forest.getTree(uri.toString())
  if (!tree) {
    tree = forest.createTree(uri.toString(), currentFile.getText())
  }

  const query = forest.language.query(
    `
      (
        (link
          link_name: (_) @name) @link
        (#select-adjacent! @link)
      ) 
    `
  ) as Query

  const queryMatches = query.matches(tree.rootNode)
  const links = mapLinkQueryMatches(queryMatches)

  if (links.find(l => ((l.name === objectName && l?.from === fromPackageName) || l.imports.includes(objectName)))) {
    return null
  }

  let text = currentFile.getText()

  const isSpecFile = !!currentFile.uri.path.split('/').pop().match(/\_spec/)

  let linkText = ''
  let offset = ''

  let lineNumber = 0
  let startCharPos = 0
  let endCharPos = 0

  if (isSpecFile) {
    linkText = buildLinkText(objectName, fromPackageName, toPackageName, type, isSpecFile, linkPath)

    if (links.length === 0) {
      const rspecDescribePresent = text.split("\n").some((line, index) => {
        if (line.match(/RSpec\.describe/)) {
          lineNumber = index
          startCharPos = line.indexOf("RSpec.describe")
          endCharPos = line.length
          return true
        }
      })
      if (!rspecDescribePresent) { return }
  
      offset = startCharPos === 0 ? (' '.repeat(TAB_LENGTH)) : (' '.repeat(startCharPos + TAB_LENGTH)) 
      linkText = `\n${offset}${linkText}\n`
    } else {
      let firstLink = queryMatches[0].captures[0].node
      lineNumber = firstLink.startPosition.row
      endCharPos = firstLink.startPosition.column

      offset = ' '.repeat(firstLink.startPosition.column)
      linkText = `${linkText}\n${offset}`
    }

    return editDocument(currentFile, lineNumber, endCharPos, linkText)
  }

  const isLinkDslPresent = text.split("\n").some((line, index) => { 
    if (line.match(/include\sRee::LinkDSL/)) {
      lineNumber = index + 1
      endCharPos = line.length
      startCharPos = line.indexOf("include Ree::LinkDSL")
      return true
    }
  })

  linkText = buildLinkText(objectName, fromPackageName, toPackageName, type, isSpecFile, linkPath)

  if (isLinkDslPresent) {
    if (links.length === 0) {
      // LinkDSL, don't have links
      offset = startCharPos === 0 ? '' : ' '.repeat(startCharPos)
      linkText = `\n${offset}${linkText}\n`
    } else {
      // LinkDSL, have links
      lineNumber = queryMatches[0].captures[0].node.startPosition.row - 1
      startCharPos = queryMatches[0].captures[0].node.startPosition.column
      endCharPos = queryMatches[0].captures[0].node.startPosition.column

      offset = ' '.repeat(startCharPos) 

      linkText = buildLinkText(objectName, fromPackageName, toPackageName, type, isSpecFile, linkPath)

      linkText = `\n${offset}${linkText}`
    }

    return editDocument(currentFile, lineNumber, endCharPos, linkText)
  }

  if (links.length === 0) {
    // block, don't have links
    const isLinksBlock = text.split('\n').some((line, index) => {
      let searchIndex = line.search(/(fn|bean|dao|mapper|async\_bean)\s\:[A-Za-z\_]+/)
      if (searchIndex !== -1) { 
        lineNumber = index
        endCharPos = line.length
        startCharPos = searchIndex
        return true
      }
    })

    if (!isLinksBlock) {
      vscode.window.showWarningMessage('LinkDSL or object block not found!')
      return
    }

    offset = startCharPos === 0 ? (' '.repeat(TAB_LENGTH)) : (' '.repeat(startCharPos + TAB_LENGTH)) 
    linkText = `\n${offset}${linkText}`
  } else {
    // block, have links
    lineNumber = queryMatches[0].captures[0].node.startPosition.row
    startCharPos = queryMatches[0].captures[0].node.startPosition.column
    endCharPos = queryMatches[0].captures[0].node.startPosition.column

    offset = ' '.repeat(startCharPos) 
    linkText = `${linkText}\n${offset}`
  }

  return editDocument(currentFile, lineNumber, endCharPos, linkText)
}

function buildLinkText(
  objectName: string,
  fromPackageName: string,
  toPackageName: string,
  type: CompletionItemKind,
  isSpecFile: boolean,
  linkPath?: string
): string {
  let link = ''
  if (type === CompletionItemKind.Method) {
    link = `link :${objectName}`

    if (fromPackageName !== toPackageName || isSpecFile) {
      link += `, from: :${fromPackageName}`
    }
  }

  if (type === CompletionItemKind.Class) {
    let pathToFile = linkPath.split('package/').pop().replace(/\.rb/, '')
    link = `link "${pathToFile}", -> { ${objectName} }`
  }

  return link
}

function editDocument(currentFile: vscode.TextDocument, line: number, character: number, insertString: string): Thenable<boolean> {
  return vscode.workspace.openTextDocument(vscode.Uri.parse(currentFile.fileName)).then((f: vscode.TextDocument) => {
    const edit = new vscode.WorkspaceEdit()

    edit.insert(f.uri, new vscode.Position(line, character), insertString)
    return vscode.workspace.applyEdit(edit).then(() => {
      forest.updateTree(currentFile.uri.toString(), currentFile.getText())

      return true
    })
  })
}

function spliceSlice(str: string, index: number, count: number, add: string) {
  return str.slice(0, index) + (add || "") + str.slice(index + count)
}