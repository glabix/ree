/**
 * Forest
 */

 import { Tree, QueryMatch, SyntaxNode } from 'web-tree-sitter'
 import { TextDocument } from 'vscode-languageserver-textdocument'
 import TreeSitterFactory from './utils/treeSitterFactory'
import { Position } from 'vscode-languageserver'

 // eslint-disable-next-line @typescript-eslint/naming-convention
 const Parser = require('web-tree-sitter')
 
 export interface IForest {
   getTree(uri: string): Tree
   createTree(uri: string, content: string): Tree
   updateTree(uri: string, content: string): Tree
   deleteTree(uri: string): boolean
 }
 
 class Forest implements IForest {
   public parser: typeof Parser
   private readonly trees: Map<string, Tree>
 
   constructor() {
     this.trees = new Map()
     this.parser = TreeSitterFactory.build()
   }
 
   public getTree(uri: string): Tree {
     return this.trees.get(uri)!
   }
 
   public createTree(uri: string, content: string): Tree {
     const tree: Tree = this.parser.parse(content)
     this.trees.set(uri, tree)
 
     return tree
   }
 
   // For the time being this is a full reparse for every change
   // Once we can support incremental sync we can use tree-sitter's
   // edit functionality
   public updateTree(uri: string, content: string): Tree {
     let tree: Tree = this.getTree(uri) || undefined
     if (tree !== undefined) {
       tree = this.parser.parse(content)
       this.trees.set(uri, tree)
     } else {
       tree = this.createTree(uri, content)
     }
 
     return tree
   }
 
   public deleteTree(uri: string): boolean {
     const tree = this.getTree(uri)
     if (tree !== undefined) {
       tree.delete()
     }
     return this.trees.delete(uri)
   }
 
   public release(): void {
     this.trees.forEach(tree => tree.delete())
     this.parser.delete()
   }
 }
 
 export const forest = new Forest()

 export interface ILink {
  name: string,
  body: string,
  from: string,
  as: string,
  imports: string[],
  isSymbol: boolean,
  queryMatch: QueryMatch
}

export const importRegexp = /(import\:\s)?(\-\>\s?\{(?<import>.+)\})/
export const fromRegexp = /from\:\s(?<from>(\:\w+)|((\'|\")\w+(\/\w+)*(\'|\")))/
export const asRegexp = /as\:\s\:(\w+)/

export function mapLinkQueryMatches(matches: QueryMatch[]): Array<ILink> {
  return matches.map(qm => {
    let from = null
    let name = qm.captures[1].node.text
    let body = qm.captures[0].node.text
    let as = body.match(asRegexp)?.[1]
    let importsString = body.match(importRegexp)?.groups?.import
    let imports: string[] = []
    if (importsString) {
      imports = importsString.trim().split(' & ')
    }
    let isSymbol = name[0] === ":"
    name = name.replace(/\"|\'|\:/g, '') 

    if (isSymbol) {
      from = qm.captures[0].node.text.match(fromRegexp)?.groups?.from
    } else {
      from = name.split('/')[0]
    }
    from = from?.replace(/\"|\'|\:/g, '')

    return { name: name, body: body, as: as, from: from, imports: imports, isSymbol: isSymbol, queryMatch: qm } as ILink
  })
}

export function findTokenNodeInTree(token: string | undefined, tree: Tree, position: Position): SyntaxNode | null {
  let tokenNode: SyntaxNode | null = null
  if (!token) { return tokenNode }
 
  const cursor = tree.walk()
  const walk = (depth: number): void => {
    if (cursor.currentNode().text.match(`${token}`) && isPositionInsideNode(position, cursor.currentNode())) {
      tokenNode = cursor.currentNode()
    }
    if (cursor.gotoFirstChild()) {
      do {
        walk(depth + 1)
      } while (cursor.gotoNextSibling())
      cursor.gotoParent()
    }
  }
  walk(0)
  cursor.delete()

  return tokenNode
}

export function isPositionInsideNode(position: Position, node: SyntaxNode) {
  if (
    node.startPosition.row <= position.line && node.endPosition.row >= position.line &&
    node.startPosition.column <= position.character && node.endPosition.column >= position.character
  ) { return true }

  return false
}
