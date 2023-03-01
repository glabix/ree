import { Location, Hover, MarkupKind } from 'vscode-languageserver'
import { Position, } from 'vscode-languageserver-textdocument'
import { Query } from 'web-tree-sitter'
import { documents } from '../documentManager'
import { forest, mapLinkQueryMatches } from '../forest'
import { getGemDir, getCachedIndex, IPackageSchema, IGemPackageSchema, IObjectMethod, isCachedIndexIsEmpty } from '../utils/packagesUtils'
import { RUBY_EXT } from './constants'
import { getPackageNameFromPath, getProjectRootDir } from './packageUtils'
import { logInfoMessage } from './stringUtils'

const url = require('node:url')
const path = require('path')
const fs = require('fs')
const ARG_REGEXP_GLOBAL = /((\:[A-Za-z_]*\??)|(\"[A-Za-z_]*\"))\s\=\>\s(\w*)?(\[(.*?)\])?/g

export function extractToken(uri: string, position: Position): string | undefined {
  const doc = documents.get(uri)

  if (!doc) {
    console.log('document not found', uri)
    return
  }

  const line = doc.getText().split("\n")[position.line]
  if (!line) { return }

  const right = line.substring(position.character)
  let left = ""

  if (position.character > 1) {
    left = line.substring(0, position.character)
  }

  const reverseLeft = left.split("").reverse().join("")
  const leftMatchData = reverseLeft.match(/^\.?([a-zA-Z_]*)[^a-zA-Z_]*/)
  let lToken = ''

  if (reverseLeft.length) {
    if (leftMatchData && leftMatchData[1]) {
      lToken = leftMatchData[1].split("").reverse().join("")
    }
  }

  const rightMatchData = right.match(/^\.?([a-zA-Z_]*)\.?[^a-zA-Z_]*/)
  let rToken = ''

  if (right.length) {
    if (rightMatchData && rightMatchData[1]) { 
      rToken = rightMatchData[1]
    }
  }

  if (lToken.length || rToken.length) {
    return `${lToken}${rToken}`
  } else {
    return undefined
  }
}

export interface IArg {
  arg: string
  type: string
}

export interface ILinkedObject {
  linkDef: string,
  method: IObjectMethod | null
  location: Location
}

export function findLinkedObject(uri: string, token: string, position: Position): ILinkedObject  {
  const defaultObject = {} as ILinkedObject
  let filePath = ''

  try {
    filePath = url.fileURLToPath(uri)
  } catch {
    return defaultObject
  }

  const index = getCachedIndex()
  if (isCachedIndexIsEmpty()) {
    logInfoMessage('Index is empty in findLinkedObject')
    return defaultObject
  }

  const doc = documents.get(uri)
  let tree = forest.getTree(uri)
  if (!tree) {
    tree = forest.createTree(uri, doc.getText())
  }

  // filter that already using
  const query = tree.getLanguage().query(
    `(
      (link
         link_name: (_) @name) @link
      (#select-adjacent! @link)
    ) `
  ) as Query

  const linkQueryMatches = query.matches(tree.rootNode)
  const links = mapLinkQueryMatches(linkQueryMatches)

  const packagesSchema = index.packages_schema
  if (!packagesSchema) { return defaultObject }

  const currentPackageName = getPackageNameFromPath(filePath)
  if (!currentPackageName) { return defaultObject }

  const projectRootDir = getProjectRootDir(filePath)
  if (!projectRootDir) { return defaultObject }

  const link = links.find(l => {
    return (l.name === token) || (!l.isSymbol && l.name.includes(token)) || (l.as === token) || l.imports.includes(token)
  })

  if (link) {
    let fromPackage = link.from
    fromPackage ??= currentPackageName

    let linkedPackage: IPackageSchema | IGemPackageSchema | undefined = index.packages_schema.packages.find(p => p.name === fromPackage)
    let linkedFilePath: string
    let rootUrl: string | undefined

    if (!linkedPackage) {
      // maybe it's a gem
      linkedPackage = index.packages_schema.gem_packages.find(p => p.name === fromPackage)
      if (!linkedPackage) { return defaultObject }
    }

    let method = null
    let linkDef = ""
    rootUrl = ('gem' in linkedPackage) ? getGemDir(linkedPackage.name) : projectRootDir
    if (!rootUrl) { return defaultObject }

    if (link.isSymbol) {
      let obj = linkedPackage.objects.find(o => o.name === link.name)
      linkedFilePath = path.join(rootUrl, obj?.file_rpath)

      if (link.as && link.name !== link.as) {
        linkDef = `link :${link.name}, as: :${link.as}, from: :${fromPackage}`
      } else {
        linkDef = `link :${link.name}, from: :${fromPackage}`
      }

      if (link.imports.length > 0) {
        linkDef = linkDef + ", import: -> {" + link.imports.join(", ") + "}"
      }

      method =  obj?.mount_as === 'fn' ? obj?.methods[0] : null
    } else {
      let pathToPckgFiles = linkedPackage.entry_rpath.split("/").slice(0, -1).join("/")
      let pathToLinkFile = link.name.split("/").slice(1).join("/").concat(RUBY_EXT)
      linkedFilePath = path.join(rootUrl, pathToPckgFiles, linkedPackage.name, pathToLinkFile)
    }

    let location = null
    if (!fs.existsSync(linkedFilePath)) { return defaultObject }

    const tokenLocation = findTokenInFile(token, url.pathToFileURL(linkedFilePath))
    if (tokenLocation) {
      location = tokenLocation
    } else {
      location = {
        uri: linkedFilePath,
        range: {
          start: {
            line: 0,
            character: 0
          },
          end: {
            line: 0,
            character: 0
          }
        }
      } as Location
    }

    return {
      linkDef: linkDef,
      method: method,
      location: location
    }
  }
  
  return defaultObject
}

export interface ILocalMethod {
  position?: Position
  methodDef?: string
}

export function findMethod(doc: string, token: string): ILocalMethod {
  const methodRegexp = RegExp(`def\\s+${token}(\\s|\\n|\\\\|\\()`)
  const classMethodRegexp = RegExp(`def\\s+self.${token}(\\s|\\n|\\\\|\\()`)
  
  let lineNumber = null
  let index = 0
  let methodDef = ""

  doc.split("\n").forEach((line) => {
    if (line.match(methodRegexp)) {
      lineNumber = index
      methodDef = line.trim()
      return
    } else if (line.match(classMethodRegexp)) {
      lineNumber = index
      methodDef = line.trim()
      return
    }

    index = index + 1
  })

  if (lineNumber) {
    return {
      position: {
        line: lineNumber,
        character: methodDef.indexOf("def")
      },
      methodDef: methodDef.trim()
    } as ILocalMethod
  } else {
    return {} as ILocalMethod
  }
}

export function findMethodArgument(token: string, uri: string, position: Position): any {
  const doc = documents.get(uri)
  if (!doc) { return }

  let tree = forest.getTree(uri)
  if (!tree) {
    tree = forest.createTree(uri, doc.getText())
  }

  const query = tree.getLanguage().query(
    `(
      (contract (_) @contract_params) @contract
      .
      [
        (method (method_parameters)? @method_params) @method
      ]
      (#select-adjacent! @contract @method)
    ) @contractWithMethod`
  ) as Query

  const queryMatches = query.matches(tree.rootNode)
  if (queryMatches.length === 0) { return }

  const matchWithArg = queryMatches.filter(q => {
    let capWithTokenArg = q.captures.filter(
      _q => _q.name === 'method_params' && 
            _q.node.text.match(RegExp(`${token}`)) &&
            _q.node.startPosition.row === position.line
    )

    if (capWithTokenArg.length > 0) { return q }
  })[0]
  if (!matchWithArg) { return }

  const contractParamsCapture = matchWithArg.captures.find(c => c.name === 'contract_params')
  if (!contractParamsCapture) { return }

  const methodParamsCapture = matchWithArg.captures.find(c => c.name === 'method_params')
  if (!methodParamsCapture) { return }

  const methodParamsArr = methodParamsCapture.node.text.replace(/\(|\)/g, '').split(', ')
  const methodParamsTokenValue = methodParamsArr.find(e => e.match(RegExp(`${token}`)))
  if (!methodParamsTokenValue) { return }

  const methodParamsTokenIndex = methodParamsArr.indexOf(methodParamsTokenValue)
  if (methodParamsTokenIndex === -1) { return }

  const contractArgs = contractParamsCapture.node.children.filter(n => !n.text.match(/^(\(|\)|\,)/)).map(n => n.text.split(' => ')?.[0])
  if (contractArgs.length === 0) { return }

  const contractArgForMethodParam = contractArgs?.[methodParamsTokenIndex]
  if (!contractArgForMethodParam) { return }

  const hover = "```ruby\n" + splitArgsType(contractArgForMethodParam) + "\n```"

  return {
    contents: {
      kind: MarkupKind.Markdown,
      value: hover
    },
    range: {
      start: position,
      end: position
    } 
  } as Hover
}

export function findTokenInFile(token: string, uri: string): Location | undefined {
  let text = documents.get(uri)?.getText()
  if (!text) {
    text = fs.readFileSync(url.fileURLToPath(uri), { encoding: 'utf8'})
  }

  let resultLine: number, startCharacter: number, endCharacter : number = 0
  let onlyTokenRegexp = RegExp(`\\b${token}\\b`)
  for (let [index, line] of text.split('\n').entries()) {
    let match = line.match(onlyTokenRegexp)
    if (match && match.index) {
      resultLine = index
      startCharacter = match.index
      endCharacter = startCharacter + token.length

      return {
        uri: uri,
        range: {
          start: { line: resultLine, character: startCharacter },
          end: { line: resultLine, character: endCharacter}
        }
      }
    }
  }
}

export function splitArgsType(argType: string): string {
  const contractMatch = argType.match(/(?<contract>[A-Za-z]*)\[(?<args>.*)\]/)
  if (!contractMatch) { return argType }
  if (!contractMatch.groups) { return argType }
  if (contractMatch && contractMatch.groups.args.split(',')?.length < 2) { return argType } // if we have only one arg and don't need to split
  if (!['Ksplat', 'Kwargs'].includes(contractMatch.groups.contract)) { return argType }

  let splittedArgs = contractMatch.groups.args.match(ARG_REGEXP_GLOBAL)?.join(',\n   ')
  let resultArgs = `${contractMatch.groups.contract}[\n   ${splittedArgs}\n  ]`
  return resultArgs
}