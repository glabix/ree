import { Location } from 'vscode-languageserver'
import { Position } from 'vscode-languageserver-textdocument'
import { Query, SyntaxNode, Tree } from 'web-tree-sitter'
import { documents } from '../documentManager'
import { findTokenNodeInTree, forest, mapLinkQueryMatches } from '../forest'
import { getCachedIndex, ICachedIndex } from '../utils/packagesUtils'
import { getProjectRootDir } from '../utils/packageUtils'
import { extractToken, findTokenInFile, findLinkedObject, findMethod } from '../utils/tokenUtils'

const url = require('node:url')
const path = require('node:path')
const fs = require('node:fs')

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

    const tokenNode = findTokenNodeInTree(token, tree)
    if (tokenNode) {
      if (index && index?.classes) {
        const constantMethodDefinitions = this.getConstantMethodsFromIndex(tree, tokenNode, token, index, projectRoot)
        if (constantMethodDefinitions.length > 0) {
          return constantMethodDefinitions
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

    // search in file
    let locationInFile = findTokenInFile(token, uri)
    if (!locationInFile) { return [defaultLocation] }

    return [locationInFile]
	}

  private static getConstantMethodsFromIndex(tree: Tree, tokenNode: SyntaxNode, token: string, index: ICachedIndex, projectRoot: string): Location[] {
    // check if we inside constant instantiation
    let constantNodeText = tokenNode?.parent?.parent?.firstChild?.text
    let classes = Object.keys(index.classes)
    let objects = Object.keys(index.objects)
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
    const linksQuery = tree.getLanguage().query(
      `(
        (identifier) @call
        (#match? @call "(${links.filter(l => l.isSymbol).map(l => l.name).flat().join("|")})$")
      )`
    ) as Query

    const findParentNodeWithType = (node: SyntaxNode | null, type: string, returnParent: boolean = false): SyntaxNode | null => {
      if (node === null) { return null }
      if (!node.parent) { return node }
      if (node.parent.type === type) { return returnParent ? node.parent : node}

      return findParentNodeWithType(node.parent, type, returnParent)
    }

    const findSiblingNode = (node: SyntaxNode | null, targetNode: SyntaxNode): SyntaxNode | null => {
      if (node === null) { return null }
      if (node.equals(targetNode)) { return node }

      return findSiblingNode(node.previousSibling, targetNode)
    }

    // trying to match call-nodes (ex SomeClass.new().some_method_call)
    let identifiersCallQueryMatches = linksQuery.captures(tree.rootNode).filter(e => e.node?.parent?.type === 'call')
    let objectsFromIndexNodes = identifiersCallQueryMatches.filter(e => objects.includes(e.node.text)).map(e => e.node)
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
        if (assignmentNode) {
          return !!tokenNode?.parent?.text.match(RegExp(`^${assignmentNode?.firstChild?.text}\.`))
        }
      }
    })

    // TODO: fix finding of targetNode in objectNodes
    // let objectMatchedNodes = objectsFromIndexNodes.filter(node => {
    //   // if tokenNode inside constantNode parent
    //   // ex: SomeClass.new(id: 1).*tokenNode* or SomeClass.new(id: 1).build.*tokenNode*
    //   let nodeHaveTokenNode = !!findParentNodeWithType(node, 'assignment', false)?.children.find(c => c.equals(tokenNode)) ||
    //                           !!findParentNodeWithType(node, 'method', false)?.children.find(c => c.equals(tokenNode)) ||
    //                           !!findSiblingNode(tokenNode, node)
    //   if (nodeHaveTokenNode) {
    //     return true
    //   } else {
    //     // check if we have assignment node, then check if assignment lhs is same as tokenNode
    //     const assignmentNode = findParentNodeWithType(node, 'assignment', true)
    //     if (assignmentNode) {
    //       return !!tokenNode?.parent?.text.match(RegExp(`^${assignmentNode?.firstChild?.text}\.`))
    //     }
    //   }
    // })
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

    // if (objectMatchedNodes.length > 0) {
    //   return objectMatchedNodes.map(n => {
    //     return index.objects[n.text].map(c => {
    //       let targetMethods = c.methods.filter(m => m.name === token)
        
    //       return targetMethods.map(m => {
    //         return {
    //           uri: url.pathToFileURL(path.join(projectRoot, c.path)),
    //           range: {
    //             start: { line: m.location + 1, character: 0 },
    //             end: { line: m.location + 1, character: 0 }
    //           }
    //         } as Location
    //       })
    //     }).flat()
    //   }).flat()
    // }

    return []
  }
}