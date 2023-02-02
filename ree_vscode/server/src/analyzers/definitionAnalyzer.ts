import { Location } from 'vscode-languageserver'
import { Position } from 'vscode-languageserver-textdocument'
import { Query, SyntaxNode, Tree } from 'web-tree-sitter'
import { connection } from '..'
import { documents } from '../documentManager'
import { findTokenNodeInTree, forest, mapLinkQueryMatches } from '../forest'
import { getCachedIndex, ICachedIndex, IGemPackageSchema, IIndexedElement, IPackagesSchema, isCachedIndexIsEmpty } from '../utils/packagesUtils'
import { getLocalePath, getProjectRootDir, Locale, resolveObject } from '../utils/packageUtils'
import { logInfoMessage, LogLevel, sendDebugServerLogToClient } from '../utils/stringUtils'
import { extractToken, findTokenInFile, findLinkedObject, findMethod } from '../utils/tokenUtils'

const url = require('node:url')
const path = require('node:path')
const fs = require('node:fs')
const yaml = require('js-yaml')

export default class DefinitionAnalyzer {
	public static analyze(uri: string, position: Position): Location[] {
    let defaultLocation : Location = {
      uri: uri,
      range: {
        start: position,
        end: position
      } 
    }

    const projectRoot = getProjectRootDir(url.fileURLToPath(uri))
    if (!projectRoot) { return [defaultLocation] }

    const doc = documents.get(uri)
    if (!doc) { return [defaultLocation] }

    const token = extractToken(uri, position)
    if (!token) { return [defaultLocation] }

    let tree = forest.getTree(uri)
    if (!tree) {
      tree = forest.createTree(uri, doc.getText())
    }

    const index = getCachedIndex()
    if (isCachedIndexIsEmpty()) { 
      logInfoMessage('Index is empty in definitionAnalyzer')
      const method = findMethod(documents.get(uri).getText(), token)

      if (method.position) {
        return [{
          uri: uri,
          range: {
            start: method.position,
            end: method.position
          } 
        }] as Location[]
      }

      // search in file
      let locationInFile = findTokenInFile(token, uri)
      if (!locationInFile) { return [defaultLocation] }

      return [locationInFile]
    }

    const linkedObject = findLinkedObject(uri, token, position)
    if (linkedObject.location) {
      return [{
        uri: linkedObject.location.uri,
        range: {
          start: linkedObject.location.range.start,
          end: linkedObject.location.range.end
        } 
      }] as Location[]
    }

    const tokenNode = findTokenNodeInTree(token, tree, position)
    if (tokenNode) {

      const localeKeyLocation = this.findLocaleKey(tokenNode, uri)
      if (localeKeyLocation.length > 0) {
        return localeKeyLocation
      }

      const fileLocation = this.findFile(tokenNode, token, uri, projectRoot)
      if (fileLocation.length > 0) {
        return fileLocation
      }

      if (index && index?.classes && index?.objects) {
        const constantMethodDefinitions = this.getConstantMethodsFromIndex(tree, tokenNode, token, index, projectRoot)
        if (constantMethodDefinitions.length > 0) {
          return constantMethodDefinitions
        }

        const objectsMethodDefinitions = this.getObjectMethodsFromIndex(tree, tokenNode, token, index, projectRoot)
        if (objectsMethodDefinitions.length > 0) {
          return objectsMethodDefinitions
        }

        const filteredClassMethodsForToken = this.findFilteredMethodsFromIndex(token, index, projectRoot, 'classes')
        if (filteredClassMethodsForToken.length > 0) {
          return filteredClassMethodsForToken
        }

        const filteredObjectMethodsForToken = this.findFilteredMethodsFromIndex(token, index, projectRoot, 'objects')
        if (filteredObjectMethodsForToken.length > 0) {
          return filteredObjectMethodsForToken
        }
      }
    }

    const method = findMethod(documents.get(uri).getText(), token)
    if (method.position) {
      return [{
        uri: uri,
        range: {
          start: method.position,
          end: method.position
        } 
      }] as Location[]
    }

    // search in file
    let locationInFile = findTokenInFile(token, uri)
    if (!locationInFile) { return [defaultLocation] }

    return [locationInFile]
	}

  private static getConstantMethodsFromIndex(tree: Tree, tokenNode: SyntaxNode, token: string, index: ICachedIndex, projectRoot: string): Location[] {
    // check if we inside constant instantiation
    let constantNodeText = tokenNode?.parent?.parent?.firstChild?.text
    let classes = Object.keys(index.classes)
    if (constantNodeText && classes.includes(constantNodeText)) {
      return index.classes[constantNodeText].map(c => {
        let targetMethods = c.methods.filter(m => m.name === token)
        
        return targetMethods.map(m => {
          return {
            uri: url.pathToFileURL(path.join(projectRoot, c.path)),
            range: {
              start: { line: m.location + 1, character: 0 },
              end: { line: m.location + 1, character: 0 }
            }
          } as Location
        })
      }).flat()
    }

    const query = tree.getLanguage().query(
      `(
        (link
            link_name: (_) @name) @link
        (#select-adjacent! @link)
      ) `
    ) as Query

    const links = mapLinkQueryMatches(query.matches(tree.rootNode))

    const constantsQuery = tree.getLanguage().query(
      `(
        (constant) @call
        (#match? @call "(${links.filter(l => l.imports.length > 0).map(l => l.imports).flat().join("|")})$")
      )`
    ) as Query

    const findParentNodeWithType = (node: SyntaxNode | null, type: string, returnParent: boolean = false): SyntaxNode | null => {
      if (node === null) { return null }
      if (!node.parent) { return node }
      if (node.parent.type === type) { return returnParent ? node.parent : node}

      return findParentNodeWithType(node.parent, type, returnParent)
    }

    // trying to match call-nodes (ex SomeClass.new().some_method_call)
    let constantCallQueryMatches = constantsQuery.captures(tree.rootNode).filter(e => e.node?.parent?.type === 'call')
    let constantsFromIndexNodes = constantCallQueryMatches.filter(e => classes.includes(e.node.text)).map(e => e.node)
    let constantMatchedNodes = constantsFromIndexNodes.filter(node => {
      // if tokenNode inside constantNode parent
      // ex: SomeClass.new(id: 1).*tokenNode* or SomeClass.new(id: 1).build.*tokenNode*
      let nodeHaveTokenNode = !!findParentNodeWithType(node, 'assignment', false)?.children.find(c => c.equals(tokenNode)) ||
                              !!findParentNodeWithType(node, 'method', false)?.children.find(c => c.equals(tokenNode))
      if (nodeHaveTokenNode) {
        return true
      } else {
        // check if we have assignment node, then check if assignment lhs is same as tokenNode
        const assignmentNode = findParentNodeWithType(node, 'assignment', true)
        if (assignmentNode && assignmentNode.type !== 'program') {
          return !!tokenNode?.parent?.text.match(RegExp(`^${assignmentNode?.firstChild?.text}\.`))
        }
      }
    })

    if (constantMatchedNodes.length > 0) {
      return constantMatchedNodes.map(n => {
        return index.classes[n.text].map(c => {
          let targetMethods = c.methods.filter(m => m.name === token)
        
          return targetMethods.map(m => {
            return {
              uri: url.pathToFileURL(path.join(projectRoot, c.path)),
              range: {
                start: { line: m.location + 1, character: 0 },
                end: { line: m.location + 1, character: 0 }
              }
            } as Location
          })
        }).flat()
      }).flat()
    }

    return []
  }

  private static getObjectMethodsFromIndex(tree: Tree, tokenNode: SyntaxNode, token: string, index: ICachedIndex, projectRoot: string): Location[] {
    let objects = Object.keys(index.objects)

    const query = tree.getLanguage().query(
      `(
        (link
            link_name: (_) @name) @link
        (#select-adjacent! @link)
      ) `
    ) as Query

    const links = mapLinkQueryMatches(query.matches(tree.rootNode))
    const linksQuery = tree.getLanguage().query(
      `(
        (identifier) @call
        (#match? @call "(${links.filter(l => l.isSymbol).map(l => l.name).flat().join("|")})$")
      )`
    ) as Query

    const checkParent = (node: SyntaxNode, targetNode: SyntaxNode): SyntaxNode | null => {
      if (node === null) { return null }
      if (node.children.find(c => c.equals(targetNode))) { return node }
      if (!node.parent) { return null }
      
      return checkParent(node.parent, targetNode)
    }

    let identifiersCallQueryMatches = linksQuery.captures(tree.rootNode).filter(e => e.node?.parent?.type === 'call')
    let objectsFromIndexNodes = identifiersCallQueryMatches.filter(e => objects.includes(e.node.text)).map(e => e.node)

    let objectMatchedNodes = objectsFromIndexNodes.filter(node => {
      // if tokenNode inside parent children
      // ex: someDao.active.*tokenNode*
      let nodeHaveTokenNode = !!checkParent(node, tokenNode)
      if (nodeHaveTokenNode) {
        return true
      }

      return false
    })

    if (objectMatchedNodes.length > 0) {
      return objectMatchedNodes.map(n => {
        return index.objects[n.text].map(c => {
          let targetMethods = c.methods.filter(m => m.name === token)
        
          return targetMethods.map(m => {
            return {
              uri: url.pathToFileURL(path.join(projectRoot, c.path)),
              range: {
                start: { line: m.location - 1, character: 0 },
                end: { line: m.location - 1, character: 0 }
              }
            } as Location
          })
        }).flat()
      }).flat()
    }

    return []
  }

  private static findFilteredMethodsFromIndex(token: string, index: ICachedIndex, projectRoot: string, type: ('objects' | 'classes')): Location[] {
    const keys = Object.keys(index[type])
    const allMethods = keys.map(k => {
      let val: ICachedIndex['objects'] | ICachedIndex['classes'] = index[type]  
      return val[k].map((c) => {
        let filteredMethods = c.methods.filter(m => m.name === token)
        return filteredMethods.map(m => {
          return {
            uri: url.pathToFileURL(path.join(projectRoot, c.path)),
            range: {
              start: { line: m.location + 1, character: 0},
              end: { line: m.location + 1, character: 0 }
            }
          }
        })
      })
    }).flat(3)
    return allMethods
  }

  private static findLocaleKey(tokenNode: SyntaxNode, uri: string): Location[] {
    const filePath = url.fileURLToPath(uri)
    const localesLocations = []
    const ruLocalePath = getLocalePath(filePath, Locale.ru)
    const enLocalePath = getLocalePath(filePath, Locale.en)
    // TODO: refactor this when moving to new index
    let ruLocales = null
    let enLocales = null
    let ruValue = null
    let enValue = null
    let ruLocaleFile = null
    let enLocaleFile = null
    let ruFullKey = ''
    let enFullKey = ''
    
    if (fs.existsSync(ruLocalePath)) {
      // TODO: move locale files to index
      ruLocaleFile = fs.readFileSync(ruLocalePath, 'utf8')
      ruFullKey = `${Locale.ru}.${tokenNode.text}`

      try {
        ruLocales = yaml.load(ruLocaleFile)
      } catch (e: any) {
        ruLocales = {}
        connection.window.showErrorMessage(`LocaleParsingError: ${ruLocalePath} - ${e.toString()}`)
      }
      ruValue = resolveObject(ruFullKey, ruLocales)
    }

    if (fs.existsSync(enLocalePath)) {
      // TODO: move locale files to index
      enLocaleFile = fs.readFileSync(enLocalePath, 'utf8')    
      enFullKey = `${Locale.en}.${tokenNode.text}`

      try {
        enLocales = yaml.load(enLocaleFile)
      } catch (e: any) {
        enLocales = {}
        connection.window.showErrorMessage(`LocaleParsingError: ${enLocalePath} - ${e.toString()}`)
      }
      enValue = resolveObject(enFullKey, enLocales)
    }
    

    if (ruValue || enValue) {
      if (ruValue) {
        let ruKeyAnchors = ruFullKey.split('.').map((v, i) => `${'  '.repeat(i)}${v}:`)
        let ruLocationLine = 0
        const ruLocationCharacter = (ruKeyAnchors.length - 1) * 2
        ruLocaleFile.split("\n").some((line: string, i: number) => {
          if (ruKeyAnchors.length === 0) { return false }
          if (line.match(RegExp(`^${ruKeyAnchors[0]}`))) {
            ruKeyAnchors = ruKeyAnchors.slice(1)
            ruLocationLine = i
          }
        })
  
        if (ruLocationLine !== 0) {
          localesLocations.push(
            {
              uri: url.pathToFileURL(ruLocalePath),
              range: {
                start: { line: ruLocationLine, character: ruLocationCharacter },
                end: { line: ruLocationLine, character: ruLocationCharacter }
              }
            } as Location
          )
        }
      }
  
      if (enValue) {
        let enKeyAnchors = enFullKey.split('.').map((v, i) => `${'  '.repeat(i)}${v}:`)
        let enLocationLine = 0
        const enLocationCharacter = (enKeyAnchors.length - 1) * 2
        enLocaleFile.split("\n").some((line: string, i: number) => {
          if (enKeyAnchors.length === 0) { return false }
          if (line.match(RegExp(`^${enKeyAnchors[0]}`))) {
            enKeyAnchors = enKeyAnchors.slice(1)
            enLocationLine = i
          }
        })
  
        if (enLocationLine !== 0) {
          localesLocations.push(
            {
              uri: url.pathToFileURL(enLocalePath),
              range: {
                start: { line: enLocationLine, character: enLocationCharacter },
                end: { line: enLocationLine, character: enLocationCharacter }
              }
            } as Location
          )
        }
      }
    }

    if (localesLocations.length > 0) { return localesLocations }

    return []
  }

  private static findFile(tokenNode: SyntaxNode, token: string, uri: string, projectRoot: string): Location[] {
    const filePath = url.fileURLToPath(uri)
    const rPath = tokenNode.text

    // check if root + rpath exists
    if (fs.existsSync(path.join(projectRoot, rPath))) {
      return [{
        uri: url.pathToFileURL(path.join(projectRoot, rPath)),
        range: {
          start: {line: 0, character: 0},
          end: {line: 0, character: 0}
        }
      }]
    }

    // check if filepathDir + rPath exists
    if (fs.existsSync(path.join(path.parse(filePath).dir, rPath))) {
      return [{
        uri: url.pathToFileURL(path.join(path.parse(filePath).dir, rPath)),
        range: {
          start: {line: 0, character: 0},
          end: {line: 0, character: 0}
        }
      }]
    }
        
    return []
  }
}

