import { Range } from 'vscode'
import { Location } from 'vscode-languageserver'
import { Position, TextDocument } from 'vscode-languageserver-textdocument'
import { documents } from '../documentManager'
import { loadPackagesSchema } from '../utils/packagesUtils'
import { IObjectMethod, loadObjectSchema } from './objectUtils'
import { PackageFacade } from './packageFacade'
import { getObjectNameFromPath, getPackageNameFromPath, getProjectRootDir } from './packageUtils'

const url = require('node:url')
const path = require('path')
const fs = require('fs')

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
  let matchData = reverseLeft.match(/^([a-zA-Z_]*)[^a-zA-Z_]*/)
  let lToken = ''

  if (reverseLeft.length) {
    if (matchData && matchData[1]) {
      lToken = matchData[1].split("").reverse().join("")
    }
  }

  matchData = right.match(/^([a-zA-Z_]*)[^a-zA-Z_]*/)
  let rToken = ''

  if (right.length) {
    if (matchData && matchData[1]) { 
      rToken = matchData[1]
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
  defLocation: Location
  location: Location
}

export function findLinkedObject(uri: string, token: string): ILinkedObject  {
  const ret = {} as ILinkedObject
  let filePath = ''

  try {
    filePath = url.fileURLToPath(uri)
  } catch {
    return ret
  }

  const objectName = getObjectNameFromPath(filePath)

  if (!objectName) { return ret }

  const packages = loadPackagesSchema(filePath)
  if (!packages) { return ret }

  const packageName = getPackageNameFromPath(filePath)
  if (!packageName) { return ret }

  const pckg = packages.find(p => p.name == packageName)
  if (!pckg) { return ret }

  const projectRootDir = getProjectRootDir(filePath)
  if (!projectRootDir) { return ret }

  const packageFacade = new PackageFacade(path.join(projectRootDir, pckg.schema))

  const object = packageFacade.objects().find(o => o.name == objectName)
  if (!object) { return ret }

  const currentObject = loadObjectSchema(path.join(projectRootDir, object.schema))
  if (!currentObject) { return ret }

  const link = currentObject.links.find((l) => {
    return l.target === token || l.as === token || l.imports.includes(token)
  })

  if (!link) { return ret }

  if (link) {
    const doc = documents.get(uri)
    const linkRegexp = RegExp(`link\\s+:${link.target}`)
    let lineNumber = 0
    let startPos = 0

    doc.getText().split("\n").forEach((s, index) => {
      if (s.match(linkRegexp)) {
        lineNumber = index
        startPos = s.indexOf("link")
        return
      }
    })

    let linkDef = ""
    
    if (link.target !== link.as) {
      linkDef = `link :${link.target}, as: :${link.as}, from: :${link.package_name}`
    } else {
      linkDef = `link :${link.target}, from: :${link.package_name}`
    }

    if (link.imports.length) {
      linkDef = linkDef + ", import: -> {" + link.imports.join(", ") + "}"
    }

    const linkedPackageName = link.package_name
    const linkedPackage = packages.find(p => p.name == linkedPackageName)
    if (!linkedPackage) { return ret }

    const linkedPackageFacade = new PackageFacade(path.join(projectRootDir, linkedPackage.schema))

    const linkedObjectSchema = linkedPackageFacade.objects().find(o => o.name == link.target)
    if (!linkedObjectSchema) { return ret }

    const linkedObject = loadObjectSchema(path.join(projectRootDir, linkedObjectSchema.schema))
    if (!linkedObject) { { return ret } }

    return {
      linkDef: linkDef,
      method: linkedObject.mount_as === 'fn' ? linkedObject.methods[0] : null,
      defLocation: {
        uri: filePath,
        range: {
          start: {
            line: lineNumber,
            character: startPos,
          } as Position,
          end: {
            line: lineNumber,
            character: startPos + linkDef.length - 1,
          } as Position
        } as Range
      },
      location: {
        uri: path.join(projectRootDir, linkedObject.path),
        range: {
          start: {
            line: 0,
            character: 0,
          } as Position,
          end: {
            line: 0,
            character: 0,
          } as Position
        } as Range
      },
    } as ILinkedObject
  }
  
  return ret
}

export interface ILocalMethod {
  position?: Position
  methodDef?: string
}

export function findMethod(doc: string, token: string): ILocalMethod {
  const methodRegexp = RegExp(`def\\s+\\${token}`)
  const classMethodRegexp = RegExp(`def\\s+self.${token}`)
  
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

export function findTokenInFile(token: string, doc: TextDocument): Location | undefined {
  let resultLine: number, startCharacter: number, endCharacter : number = 0
  let onlyTokenRegexp = RegExp(`\\b${token}\\b`)
  for (let [index, line] of doc.getText().split('\n').entries()) {
    let match = line.match(onlyTokenRegexp)
    if (match && match.index) {
      resultLine = index
      startCharacter = match.index
      endCharacter = startCharacter + token.length

      return {
        uri: doc.uri,
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

  let splittedArgs = contractMatch.groups.args.split(/,\s+\:/).join(',\n   :')
  let resultArgs = `${contractMatch.groups.contract}[\n   ${splittedArgs}\n  ]`
  return resultArgs
}