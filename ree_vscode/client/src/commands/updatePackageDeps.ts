import * as vscode from 'vscode'
import { forest, Link, mapLinkQueryMatches } from '../utils/forest'
import { Query } from 'web-tree-sitter'
import { CompletionItemKind } from 'vscode-languageclient'
import { sortLinksByNameAsc } from './checkAndSortLinks'

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

  if (textDocs.map(t => t.fileName).includes(filePath) || textDocs.map(t => t.uri.toString()).includes(filePath)) {
    return new Promise(resolve => resolve(textDocs.filter(t => t.fileName === filePath || t.uri.toString() === filePath)[0]))
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

  if (links.find(l => ((l.name === objectName && (l?.from === fromPackageName || l.from === undefined)) || l.imports.includes(objectName)))) {
    return null
  }

  let text = currentFile.getText()

  const isSpecFile = !!currentFile.uri.path.split('/').pop().match(/\_spec/)

  let linkText = ''
  let offset = ''
  let linkName = ''
  let isSymbol = true

  let lineNumber = 0
  let startCharPos = 0
  let endCharPos = 0

  if (isSpecFile) {
    ({ text: linkText } = buildLinkText(objectName, fromPackageName, toPackageName, type, isSpecFile, linkPath))

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
  });

  ({ text: linkText, symbol: isSymbol, name: linkName } = buildLinkText(objectName, fromPackageName, toPackageName, type, isSpecFile, linkPath))

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

      offset = ' '.repeat(startCharPos); 

      ({ text: linkText, symbol: isSymbol, name: linkName } = buildLinkText(objectName, fromPackageName, toPackageName, type, isSpecFile, linkPath))

      if (isSymbol) {
        const symbolLinks = links.filter(l => l.isSymbol)
        if (symbolLinks.length > 0) {
          // find insert position for symbol link
        } else {
          lineNumber = queryMatches[0].captures[0].node.startPosition.row - 1
          startCharPos = queryMatches[0].captures[0].node.startPosition.column
          endCharPos = queryMatches[0].captures[0].node.startPosition.column
        }
      }

      linkText = `\n${offset}${linkText}`
    }

    return editDocument(currentFile, lineNumber, endCharPos, linkText)
  }

  const isLinksBlock = text.split('\n').some((line, index) => {
    let searchIndex = line.search(/(fn|bean|dao|mapper|async\_bean)\s\:[A-Za-z\_]+/)
    if (searchIndex !== -1) { 
      lineNumber = index
      endCharPos = line.length
      startCharPos = searchIndex
      return true
    }
  })

  if (links.length === 0) {
    // maybe a block and we don't have links
    offset = startCharPos === 0 ? (' '.repeat(TAB_LENGTH)) : (' '.repeat(startCharPos + TAB_LENGTH))
    
    if (text.split("\n")[lineNumber].match(/\sdo/)) {
      linkText = `\n${offset}${linkText}`
    } else {
      if (!isLinksBlock) {
        const includeQuery = forest.language.query(
          `(
            (call) @include
            (#match? @include "^include")
           )
          `
        ) as Query

        const includeMatches = includeQuery.matches(tree.rootNode)
        if (includeMatches.length > 0) {
          let lastIncludeNode = includeMatches[includeMatches.length - 1].captures[0].node
          if (lastIncludeNode.text.match(/include\sRee\:\:LinkDSL/)) {
            lastIncludeNode = includeMatches[includeMatches.length - 2].captures[0].node
          }

          lineNumber = lastIncludeNode.startPosition.row
          endCharPos = lastIncludeNode.endPosition.column
          linkText = `\n${offset}include Ree::LinkDSL\n\n${offset}${linkText}`
        } else {
          const classQuery = forest.language.query(`(class) @class`)
          const classMatches = classQuery.matches(tree.rootNode)

          if (classMatches.length > 0) {
            const classNameNode = classMatches[0].captures[0].node.children[1]
            lineNumber = classNameNode.startPosition.row
            endCharPos = classNameNode.endPosition.column
            linkText = `\n${offset}include Ree::LinkDSL\n\n${offset}${linkText}`
          } else {
            linkText = `${linkText}\n`
          }
        }
      } else {
        linkText = ` do\n${offset}${linkText}\n${' '.repeat(startCharPos)}end`
      }
    }
  } else {
    // maybe a block and we already *have* links
    if (text.split("\n")[lineNumber].match(/\sdo/)) {
      lineNumber = queryMatches[0].captures[0].node.startPosition.row
      startCharPos = queryMatches[0].captures[0].node.startPosition.column
      endCharPos = queryMatches[0].captures[0].node.startPosition.column
  
      offset = ' '.repeat(startCharPos) 
    
      const symbolLinks = links.filter(l => l.isSymbol).sort(sortLinksByNameAsc)
      const stringLinks = links.filter(l => !l.isSymbol).sort(sortLinksByNameAsc)
  
      // TODO: refactor this block later!
      if (isSymbol) {
        if (symbolLinks.length > 0) {
          let newLinkIndex = [...symbolLinks, { name: linkName } as Link].sort(sortLinksByNameAsc).findIndex(l => l.name === linkName)
          if (newLinkIndex === 0) {
            // if it must be first
            lineNumber = symbolLinks[0].queryMatch.captures[0].node.startPosition.row
            startCharPos = symbolLinks[0].queryMatch.captures[0].node.startPosition.column
            endCharPos = symbolLinks[0].queryMatch.captures[0].node.startPosition.column
            linkText = `${linkText}\n${offset}`
          } else if (newLinkIndex === (symbolLinks.length)) {
            // if it must be last
            lineNumber = symbolLinks[symbolLinks.length - 1].queryMatch.captures[0].node.startPosition.row
            startCharPos = symbolLinks[symbolLinks.length - 1].queryMatch.captures[0].node.endPosition.column
            endCharPos = symbolLinks[symbolLinks.length - 1].queryMatch.captures[0].node.endPosition.column
            linkText = `\n${offset}${linkText}`
          } else {
            // if it must be somewhere between
            lineNumber = symbolLinks[newLinkIndex - 1].queryMatch.captures[0].node.startPosition.row
            startCharPos = symbolLinks[newLinkIndex - 1].queryMatch.captures[0].node.endPosition.column
            endCharPos = symbolLinks[newLinkIndex - 1].queryMatch.captures[0].node.endPosition.column
            linkText = `\n${offset}${linkText}`
          }
        } else {
          lineNumber = queryMatches[queryMatches.length - 1].captures[0].node.startPosition.row
          startCharPos = queryMatches[queryMatches.length - 1].captures[0].node.startPosition.column
          endCharPos = queryMatches[queryMatches.length - 1].captures[0].node.startPosition.column
          linkText = `${linkText}\n${offset}`
        }
      } else {
        if (stringLinks.length > 0) {
          let newLinkIndex = [...stringLinks, { name: linkName } as Link].sort(sortLinksByNameAsc).findIndex(l => l.name === linkName)
          if (newLinkIndex === 0) {
            // if it must be first
            lineNumber = stringLinks[0].queryMatch.captures[0].node.startPosition.row
            startCharPos = stringLinks[0].queryMatch.captures[0].node.startPosition.column
            endCharPos = stringLinks[0].queryMatch.captures[0].node.startPosition.column
            linkText = `${linkText}\n${offset}`
          } else if (newLinkIndex === (stringLinks.length)) {
            // if it must be last
            lineNumber = stringLinks[stringLinks.length - 1].queryMatch.captures[0].node.startPosition.row
            startCharPos = stringLinks[stringLinks.length - 1].queryMatch.captures[0].node.endPosition.column
            endCharPos = stringLinks[stringLinks.length - 1].queryMatch.captures[0].node.endPosition.column
            linkText = `\n${offset}${linkText}`
          } else {
            // if it must be somewhere between
            lineNumber = stringLinks[newLinkIndex - 1].queryMatch.captures[0].node.startPosition.row
            startCharPos = stringLinks[newLinkIndex - 1].queryMatch.captures[0].node.endPosition.column
            endCharPos = stringLinks[newLinkIndex - 1].queryMatch.captures[0].node.endPosition.column
            linkText = `\n${offset}${linkText}`
          }
        } else {
          lineNumber = queryMatches[queryMatches.length - 1].captures[0].node.startPosition.row
          startCharPos = queryMatches[queryMatches.length - 1].captures[0].node.endPosition.column
          endCharPos = queryMatches[queryMatches.length - 1].captures[0].node.endPosition.column
          linkText = `\n${offset}${linkText}`
        }
      }
    } else {
      if (!isLinksBlock) {
        const includeQuery = forest.language.query(
          `(
            (call) @include
            (#match? @include "^include")
           )
          `
        ) as Query

        const includeMatches = includeQuery.matches(tree.rootNode)
        if (includeMatches.length > 0) {
          let lastIncludeNode = includeMatches[includeMatches.length - 1].captures[0].node
          if (lastIncludeNode.text.match(/include\sRee\:\:LinkDSL/)) {
            lastIncludeNode = includeMatches[includeMatches.length - 2].captures[0].node
          }

          lineNumber = lastIncludeNode.startPosition.row
          endCharPos = lastIncludeNode.endPosition.column
          offset = ' '.repeat(lastIncludeNode.startPosition.column)
          linkText = `\n${offset}include Ree::LinkDSL\n\n${offset}${linkText}`
        } else {
          const classQuery = forest.language.query(`(class) @class`)
          const classMatches = classQuery.matches(tree.rootNode)

          if (classMatches.length > 0) {
            const classNameNode = classMatches[0].captures[0].node.children[1]
            lineNumber = classNameNode.startPosition.row
            endCharPos = classNameNode.endPosition.column
            offset = ' '.repeat(
              classNameNode.startPosition.column === 0 ? TAB_LENGTH : classNameNode.startPosition.column * TAB_LENGTH
            )
            linkText = `\n${offset}include Ree::LinkDSL\n\n${offset}${linkText}`
          } else {
            linkText = `${linkText}\n`
          }
        }
      } else {
        linkText = ` do\n${offset}${linkText}\n${' '.repeat(startCharPos)}end`
      }
    }
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
): { text: string, symbol: boolean, name: string } {
  let obj = {
    text: '',
    symbol: true,
    name: ''
  }

  if (type === CompletionItemKind.Method) {
    obj.text = `link :${objectName}`
    obj.name = objectName

    if (fromPackageName !== toPackageName || isSpecFile) {
      obj.text += `, from: :${fromPackageName}`
    }
  }

  if (type === CompletionItemKind.Class) {
    let pathToFile = linkPath.split('package/').pop().replace(/\.rb/, '')
    obj.text = `link "${pathToFile}", -> { ${objectName} }`
    obj.symbol = false
    obj.name = pathToFile
  }

  return obj
}

function editDocument(currentFile: vscode.TextDocument, line: number, character: number, insertString: string): Thenable<boolean> {
  return vscode.workspace.openTextDocument(currentFile.uri).then((f: vscode.TextDocument) => {
    const edit = new vscode.WorkspaceEdit()

    edit.insert(f.uri, new vscode.Position(line, character), insertString)
    return vscode.workspace.applyEdit(edit).then(() => {
      forest.updateTree(currentFile.uri.toString(), currentFile.getText())

      return true
    })
  })
}

function sortedIndex(array, value) {
	let low = 0, high = array.length

	while (low < high) {
    let mid = ~~((low + high) / 2)
    console.log('mid', mid)
    if (array[mid].localeCompare(value) <= 0) {
      low = mid + 1
    } else { 
      high = mid
    }
	}
	return low
}

function spliceSlice(str: string, index: number, count: number, add: string) {
  return str.slice(0, index) + (add || "") + str.slice(index + count)
}